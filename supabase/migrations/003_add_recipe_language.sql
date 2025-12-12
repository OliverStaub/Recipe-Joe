-- Migration: 003_add_recipe_language.sql
-- Adds language column to track which language the recipe was imported in

ALTER TABLE recipes ADD COLUMN language TEXT DEFAULT 'en';

-- Add index for potential filtering by language
CREATE INDEX idx_recipes_language ON recipes(language);
