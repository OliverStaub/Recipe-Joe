-- Migration: 002_seed_measurement_types.sql
-- Seed data for common measurement types

INSERT INTO measurement_types (name_en, name_de, abbreviation_en, abbreviation_de) VALUES
-- Volume - Small
('teaspoon', 'Teelöffel', 'tsp', 'TL'),
('tablespoon', 'Esslöffel', 'tbsp', 'EL'),
('fluid ounce', 'Flüssigunze', 'fl oz', 'fl oz'),

-- Volume - Medium
('cup', 'Tasse', 'cup', 'Tasse'),
('milliliter', 'Milliliter', 'ml', 'ml'),
('deciliter', 'Deziliter', 'dl', 'dl'),

-- Volume - Large
('liter', 'Liter', 'L', 'L'),
('quart', 'Quart', 'qt', 'qt'),
('gallon', 'Gallone', 'gal', 'gal'),

-- Weight - Small
('gram', 'Gramm', 'g', 'g'),
('ounce', 'Unze', 'oz', 'oz'),

-- Weight - Large
('kilogram', 'Kilogramm', 'kg', 'kg'),
('pound', 'Pfund', 'lb', 'Pfd'),

-- Count/Pieces
('piece', 'Stück', 'pc', 'St'),
('slice', 'Scheibe', 'slice', 'Scheibe'),
('clove', 'Zehe', 'clove', 'Zehe'),
('bunch', 'Bund', 'bunch', 'Bund'),
('sprig', 'Zweig', 'sprig', 'Zweig'),
('leaf', 'Blatt', 'leaf', 'Blatt'),

-- Approximate/Imprecise
('pinch', 'Prise', 'pinch', 'Prise'),
('dash', 'Spritzer', 'dash', 'Spritzer'),
('handful', 'Handvoll', 'handful', 'Handvoll'),
('to taste', 'nach Geschmack', 'to taste', 'n.G.'),
('some', 'etwas', 'some', 'etwas'),

-- Containers
('can', 'Dose', 'can', 'Dose'),
('package', 'Packung', 'pkg', 'Pkg'),
('jar', 'Glas', 'jar', 'Glas'),
('bottle', 'Flasche', 'bottle', 'Fl'),
('bag', 'Beutel', 'bag', 'Btl'),
('box', 'Schachtel', 'box', 'Schachtel');
