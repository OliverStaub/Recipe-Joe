-- ============================================================================
-- RecipeJoe initial schema
--
-- Recipes are SHARED CONTENT keyed by (source_url, language). When two users
-- import the same URL in the same language, we link both of them to the same
-- recipe rather than re-running the Claude extraction.
--
-- Per-user state lives on `user_recipes` (their library + favourite/rating)
-- and `recipe_imports` (in-flight imports, used by the home screen to render
-- "importing…" placeholders).
--
-- Schema is normalised: ingredients and measurement units are shared lookups,
-- joined to recipes via `recipe_ingredients`. Steps are 1-to-many on `recipes`.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ----------------------------------------------------------------------------
-- Shared lookup tables
-- ----------------------------------------------------------------------------
CREATE TABLE measurement_types (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_en         TEXT NOT NULL UNIQUE,
    name_de         TEXT NOT NULL UNIQUE,
    abbreviation_en TEXT NOT NULL,
    abbreviation_de TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE ingredients (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_en     TEXT NOT NULL UNIQUE,
    name_de     TEXT NOT NULL UNIQUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ingredients_name_en_trgm ON ingredients USING gin(name_en gin_trgm_ops);
CREATE INDEX idx_ingredients_name_de_trgm ON ingredients USING gin(name_de gin_trgm_ops);

-- ----------------------------------------------------------------------------
-- Shared recipes (deduplicated by source_url + language)
-- ----------------------------------------------------------------------------
CREATE TABLE recipes (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_url          TEXT NOT NULL,
    language            TEXT NOT NULL CHECK (language IN ('en', 'de')),
    name                TEXT NOT NULL,
    author              TEXT,
    description         TEXT,
    prep_time_minutes   INTEGER,
    cook_time_minutes   INTEGER,
    total_time_minutes  INTEGER,
    recipe_yield        TEXT,
    category            TEXT,
    cuisine             TEXT,
    image_url           TEXT,
    keywords            TEXT[] NOT NULL DEFAULT '{}',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (source_url, language)
);

CREATE INDEX idx_recipes_source_url ON recipes(source_url);
CREATE INDEX idx_recipes_name_trgm ON recipes USING gin(name gin_trgm_ops);

CREATE TABLE recipe_steps (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id         UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    step_number       INTEGER NOT NULL,
    instruction       TEXT NOT NULL,
    duration_minutes  INTEGER,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (recipe_id, step_number)
);
CREATE INDEX idx_recipe_steps_recipe_id ON recipe_steps(recipe_id, step_number);

CREATE TABLE recipe_ingredients (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id           UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    ingredient_id       UUID NOT NULL REFERENCES ingredients(id),
    measurement_type_id UUID REFERENCES measurement_types(id),
    quantity            NUMERIC(10, 3),
    notes               TEXT,
    display_order       INTEGER NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_recipe_ingredients_recipe ON recipe_ingredients(recipe_id, display_order);
CREATE INDEX idx_recipe_ingredients_ingredient ON recipe_ingredients(ingredient_id);

-- ----------------------------------------------------------------------------
-- Per-user state
-- ----------------------------------------------------------------------------
CREATE TABLE user_recipes (
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    recipe_id   UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
    rating      SMALLINT CHECK (rating IS NULL OR (rating >= 0 AND rating <= 5)),
    saved_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, recipe_id)
);
CREATE INDEX idx_user_recipes_user_saved ON user_recipes(user_id, saved_at DESC);

CREATE TYPE recipe_import_status AS ENUM ('queued', 'running', 'done', 'error');

CREATE TABLE recipe_imports (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    source_url      TEXT NOT NULL,
    language        TEXT NOT NULL CHECK (language IN ('en', 'de')),
    status          recipe_import_status NOT NULL DEFAULT 'queued',
    error_message   TEXT,
    recipe_id       UUID REFERENCES recipes(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_recipe_imports_user_pending ON recipe_imports(user_id, created_at DESC)
    WHERE status IN ('queued', 'running', 'error');

-- ----------------------------------------------------------------------------
-- updated_at triggers
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER recipes_set_updated_at
    BEFORE UPDATE ON recipes
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER recipe_imports_set_updated_at
    BEFORE UPDATE ON recipe_imports
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ----------------------------------------------------------------------------
-- Row-level security
--   Recipes (and their steps/ingredients) are world-readable for authenticated
--   users — they're imported from public URLs and dedup is the whole point.
--   Writes happen through the service-role edge function only.
--   user_recipes / recipe_imports are strictly per-user.
-- ----------------------------------------------------------------------------
ALTER TABLE recipes                ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_steps           ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_ingredients     ENABLE ROW LEVEL SECURITY;
ALTER TABLE ingredients            ENABLE ROW LEVEL SECURITY;
ALTER TABLE measurement_types      ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_recipes           ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_imports         ENABLE ROW LEVEL SECURITY;

CREATE POLICY recipes_read         ON recipes            FOR SELECT TO authenticated USING (true);
CREATE POLICY recipe_steps_read    ON recipe_steps       FOR SELECT TO authenticated USING (true);
CREATE POLICY recipe_ings_read     ON recipe_ingredients FOR SELECT TO authenticated USING (true);
CREATE POLICY ingredients_read     ON ingredients        FOR SELECT TO authenticated USING (true);
CREATE POLICY measurement_read     ON measurement_types  FOR SELECT TO authenticated USING (true);

CREATE POLICY user_recipes_owner   ON user_recipes
    FOR ALL TO authenticated
    USING      (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY recipe_imports_owner ON recipe_imports
    FOR ALL TO authenticated
    USING      (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

-- ----------------------------------------------------------------------------
-- Storage: public bucket for imported images
-- ----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('recipe-images', 'recipe-images', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY recipe_images_read
    ON storage.objects FOR SELECT
    USING (bucket_id = 'recipe-images');
