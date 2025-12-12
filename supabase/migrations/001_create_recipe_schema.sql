-- Migration: 001_create_recipe_schema.sql
-- Creates the normalized recipe database schema

-- Enable trigram extension for fuzzy search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ============================================
-- SHARED TABLES (ingredients, measurement types)
-- ============================================

-- Measurement Types (grams, cups, tablespoons, etc.)
CREATE TABLE measurement_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_en TEXT NOT NULL,
    name_de TEXT NOT NULL,
    abbreviation_en TEXT NOT NULL,
    abbreviation_de TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(name_en),
    UNIQUE(name_de)
);

-- Ingredients (shared across all users)
CREATE TABLE ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_en TEXT NOT NULL,
    name_de TEXT NOT NULL,
    default_measurement_type_id UUID REFERENCES measurement_types(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(name_en),
    UNIQUE(name_de)
);

-- Junction: Which measurement types are valid for each ingredient
CREATE TABLE ingredient_measurement_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    measurement_type_id UUID NOT NULL REFERENCES measurement_types(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(ingredient_id, measurement_type_id)
);

-- ============================================
-- USER-SPECIFIC TABLES
-- ============================================

-- Recipes (user_id nullable for development without auth)
CREATE TABLE recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID, -- Nullable for dev, will reference auth.users when auth enabled
    name TEXT NOT NULL,
    author TEXT,
    description TEXT,
    prep_time_minutes INTEGER,
    cook_time_minutes INTEGER,
    total_time_minutes INTEGER,
    recipe_yield TEXT,
    category TEXT,
    cuisine TEXT,
    rating INTEGER DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
    is_favorite BOOLEAN DEFAULT FALSE,
    image_url TEXT,
    source_url TEXT,
    keywords TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Recipe Steps
CREATE TABLE recipe_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    step_number INTEGER NOT NULL,
    instruction TEXT NOT NULL,
    duration_minutes INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(recipe_id, step_number)
);

-- Recipe Ingredients (junction table)
CREATE TABLE recipe_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES ingredients(id),
    measurement_type_id UUID REFERENCES measurement_types(id),
    quantity DECIMAL(10, 3),
    notes TEXT,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX idx_recipes_user_id ON recipes(user_id);
CREATE INDEX idx_recipes_category ON recipes(category);
CREATE INDEX idx_recipes_cuisine ON recipes(cuisine);
CREATE INDEX idx_recipes_is_favorite ON recipes(is_favorite);
CREATE INDEX idx_recipes_created_at ON recipes(created_at DESC);

CREATE INDEX idx_recipe_steps_recipe_id ON recipe_steps(recipe_id);
CREATE INDEX idx_recipe_steps_order ON recipe_steps(recipe_id, step_number);

CREATE INDEX idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id);
CREATE INDEX idx_recipe_ingredients_ingredient_id ON recipe_ingredients(ingredient_id);

CREATE INDEX idx_ingredients_name_en ON ingredients(name_en);
CREATE INDEX idx_ingredients_name_de ON ingredients(name_de);

-- Trigram indexes for fuzzy search on ingredient names
CREATE INDEX idx_ingredients_name_en_trgm ON ingredients USING gin(name_en gin_trgm_ops);
CREATE INDEX idx_ingredients_name_de_trgm ON ingredients USING gin(name_de gin_trgm_ops);

-- ============================================
-- UPDATED_AT TRIGGER
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_recipes_updated_at
    BEFORE UPDATE ON recipes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
