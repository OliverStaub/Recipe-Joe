-- Migration: 004_enable_rls.sql
-- Enable Row Level Security and create policies for multi-user support

-- ============================================
-- ENABLE RLS ON ALL TABLES
-- ============================================

ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE measurement_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE ingredient_measurement_types ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RECIPES TABLE POLICIES
-- Users can only access their own recipes
-- ============================================

CREATE POLICY "Users can view own recipes"
ON recipes FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own recipes"
ON recipes FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own recipes"
ON recipes FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own recipes"
ON recipes FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- RECIPE_STEPS TABLE POLICIES
-- Access controlled via recipe ownership
-- ============================================

CREATE POLICY "Users can view own recipe steps"
ON recipe_steps FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM recipes
        WHERE recipes.id = recipe_steps.recipe_id
        AND recipes.user_id = auth.uid()
    )
);

CREATE POLICY "Users can insert own recipe steps"
ON recipe_steps FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM recipes
        WHERE recipes.id = recipe_steps.recipe_id
        AND recipes.user_id = auth.uid()
    )
);

CREATE POLICY "Users can update own recipe steps"
ON recipe_steps FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM recipes
        WHERE recipes.id = recipe_steps.recipe_id
        AND recipes.user_id = auth.uid()
    )
);

CREATE POLICY "Users can delete own recipe steps"
ON recipe_steps FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM recipes
        WHERE recipes.id = recipe_steps.recipe_id
        AND recipes.user_id = auth.uid()
    )
);

-- ============================================
-- RECIPE_INGREDIENTS TABLE POLICIES
-- Access controlled via recipe ownership
-- ============================================

CREATE POLICY "Users can view own recipe ingredients"
ON recipe_ingredients FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM recipes
        WHERE recipes.id = recipe_ingredients.recipe_id
        AND recipes.user_id = auth.uid()
    )
);

CREATE POLICY "Users can insert own recipe ingredients"
ON recipe_ingredients FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM recipes
        WHERE recipes.id = recipe_ingredients.recipe_id
        AND recipes.user_id = auth.uid()
    )
);

CREATE POLICY "Users can update own recipe ingredients"
ON recipe_ingredients FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM recipes
        WHERE recipes.id = recipe_ingredients.recipe_id
        AND recipes.user_id = auth.uid()
    )
);

CREATE POLICY "Users can delete own recipe ingredients"
ON recipe_ingredients FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM recipes
        WHERE recipes.id = recipe_ingredients.recipe_id
        AND recipes.user_id = auth.uid()
    )
);

-- ============================================
-- SHARED CATALOG TABLES (PUBLIC READ ACCESS)
-- These are shared across all users
-- ============================================

-- Ingredients catalog - anyone can read
CREATE POLICY "Anyone can view ingredients"
ON ingredients FOR SELECT
USING (true);

-- Service role can insert new ingredients (via Edge Functions)
CREATE POLICY "Service role can insert ingredients"
ON ingredients FOR INSERT
WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- Measurement types - anyone can read
CREATE POLICY "Anyone can view measurement types"
ON measurement_types FOR SELECT
USING (true);

-- Ingredient measurement types junction - anyone can read
CREATE POLICY "Anyone can view ingredient measurement types"
ON ingredient_measurement_types FOR SELECT
USING (true);

-- ============================================
-- STORAGE BUCKET POLICIES
-- recipe-images: Users can only access their own images
-- Folder structure: {user_id}/{recipe_id}.jpg
-- ============================================

-- Note: These policies should be run in the Supabase SQL Editor
-- as storage policies require the storage schema

-- CREATE POLICY "Users can upload own recipe images"
-- ON storage.objects FOR INSERT
-- WITH CHECK (
--     bucket_id = 'recipe-images'
--     AND auth.uid()::text = (storage.foldername(name))[1]
-- );

-- CREATE POLICY "Users can view own recipe images"
-- ON storage.objects FOR SELECT
-- USING (
--     bucket_id = 'recipe-images'
--     AND auth.uid()::text = (storage.foldername(name))[1]
-- );

-- CREATE POLICY "Users can delete own recipe images"
-- ON storage.objects FOR DELETE
-- USING (
--     bucket_id = 'recipe-images'
--     AND auth.uid()::text = (storage.foldername(name))[1]
-- );

-- recipe-imports: Authenticated users can upload temp files
-- CREATE POLICY "Authenticated users can upload temp imports"
-- ON storage.objects FOR INSERT
-- WITH CHECK (
--     bucket_id = 'recipe-imports'
--     AND auth.role() = 'authenticated'
-- );

-- CREATE POLICY "Authenticated users can view temp imports"
-- ON storage.objects FOR SELECT
-- USING (
--     bucket_id = 'recipe-imports'
--     AND auth.role() = 'authenticated'
-- );
