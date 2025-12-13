-- Migration: 005_fix_linter_warnings.sql
-- Fixes security and performance warnings from Supabase database linter

-- ============================================
-- FIX 1: FUNCTION SEARCH PATH (Security)
-- Set immutable search_path to prevent search_path injection
-- ============================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- ============================================
-- FIX 2: MOVE pg_trgm EXTENSION (Security)
-- Move from public schema to extensions schema
-- ============================================

CREATE SCHEMA IF NOT EXISTS extensions;

-- Drop existing extension and indexes
DROP INDEX IF EXISTS idx_ingredients_name_en_trgm;
DROP INDEX IF EXISTS idx_ingredients_name_de_trgm;
DROP EXTENSION IF EXISTS pg_trgm;

-- Recreate extension in extensions schema
CREATE EXTENSION pg_trgm SCHEMA extensions;

-- Recreate trigram indexes with proper schema reference
CREATE INDEX idx_ingredients_name_en_trgm ON ingredients USING gin(name_en extensions.gin_trgm_ops);
CREATE INDEX idx_ingredients_name_de_trgm ON ingredients USING gin(name_de extensions.gin_trgm_ops);

-- ============================================
-- FIX 3: RLS POLICIES (Performance)
-- Replace auth.uid() with (select auth.uid()) to prevent
-- re-evaluation for each row
-- ============================================

-- ----- RECIPES TABLE -----

DROP POLICY IF EXISTS "Users can view own recipes" ON recipes;
CREATE POLICY "Users can view own recipes"
ON recipes FOR SELECT
USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own recipes" ON recipes;
CREATE POLICY "Users can insert own recipes"
ON recipes FOR INSERT
WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own recipes" ON recipes;
CREATE POLICY "Users can update own recipes"
ON recipes FOR UPDATE
USING ((select auth.uid()) = user_id)
WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own recipes" ON recipes;
CREATE POLICY "Users can delete own recipes"
ON recipes FOR DELETE
USING ((select auth.uid()) = user_id);

-- ----- RECIPE_STEPS TABLE -----

DROP POLICY IF EXISTS "Users can view own recipe steps" ON recipe_steps;
CREATE POLICY "Users can view own recipe steps"
ON recipe_steps FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM recipes
        WHERE recipes.id = recipe_steps.recipe_id
        AND recipes.user_id = (select auth.uid())
    )
);

DROP POLICY IF EXISTS "Users can insert own recipe steps" ON recipe_steps;
CREATE POLICY "Users can insert own recipe steps"
ON recipe_steps FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM recipes
        WHERE recipes.id = recipe_steps.recipe_id
        AND recipes.user_id = (select auth.uid())
    )
);

DROP POLICY IF EXISTS "Users can update own recipe steps" ON recipe_steps;
CREATE POLICY "Users can update own recipe steps"
ON recipe_steps FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM recipes
        WHERE recipes.id = recipe_steps.recipe_id
        AND recipes.user_id = (select auth.uid())
    )
);

DROP POLICY IF EXISTS "Users can delete own recipe steps" ON recipe_steps;
CREATE POLICY "Users can delete own recipe steps"
ON recipe_steps FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM recipes
        WHERE recipes.id = recipe_steps.recipe_id
        AND recipes.user_id = (select auth.uid())
    )
);

-- ----- RECIPE_INGREDIENTS TABLE -----

DROP POLICY IF EXISTS "Users can view own recipe ingredients" ON recipe_ingredients;
CREATE POLICY "Users can view own recipe ingredients"
ON recipe_ingredients FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM recipes
        WHERE recipes.id = recipe_ingredients.recipe_id
        AND recipes.user_id = (select auth.uid())
    )
);

DROP POLICY IF EXISTS "Users can insert own recipe ingredients" ON recipe_ingredients;
CREATE POLICY "Users can insert own recipe ingredients"
ON recipe_ingredients FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM recipes
        WHERE recipes.id = recipe_ingredients.recipe_id
        AND recipes.user_id = (select auth.uid())
    )
);

DROP POLICY IF EXISTS "Users can update own recipe ingredients" ON recipe_ingredients;
CREATE POLICY "Users can update own recipe ingredients"
ON recipe_ingredients FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM recipes
        WHERE recipes.id = recipe_ingredients.recipe_id
        AND recipes.user_id = (select auth.uid())
    )
);

DROP POLICY IF EXISTS "Users can delete own recipe ingredients" ON recipe_ingredients;
CREATE POLICY "Users can delete own recipe ingredients"
ON recipe_ingredients FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM recipes
        WHERE recipes.id = recipe_ingredients.recipe_id
        AND recipes.user_id = (select auth.uid())
    )
);

-- ----- INGREDIENTS TABLE -----

DROP POLICY IF EXISTS "Service role can insert ingredients" ON ingredients;
CREATE POLICY "Service role can insert ingredients"
ON ingredients FOR INSERT
WITH CHECK ((select auth.jwt()) ->> 'role' = 'service_role');

-- ============================================
-- FIX 4: UNINDEXED FOREIGN KEYS (Performance)
-- Add covering indexes for foreign key constraints
-- ============================================

CREATE INDEX IF NOT EXISTS idx_ingredient_measurement_types_measurement_type_id
    ON ingredient_measurement_types(measurement_type_id);

CREATE INDEX IF NOT EXISTS idx_ingredients_default_measurement_type_id
    ON ingredients(default_measurement_type_id);

CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_measurement_type_id
    ON recipe_ingredients(measurement_type_id);
