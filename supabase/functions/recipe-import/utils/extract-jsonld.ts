// Utility to extract JSON-LD recipe data from HTML

import type { JsonLdRecipe } from "../types.ts";

export function extractJsonLd(html: string): JsonLdRecipe | null {
  // Match all JSON-LD script tags
  const jsonLdRegex = /<script[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
  let match;

  while ((match = jsonLdRegex.exec(html)) !== null) {
    try {
      const jsonContent = match[1].trim();
      const parsed = JSON.parse(jsonContent);

      // Handle both single object and array formats
      const items = Array.isArray(parsed) ? parsed : [parsed];

      for (const item of items) {
        // Check for Recipe type directly
        if (item["@type"] === "Recipe") {
          return item as JsonLdRecipe;
        }

        // Handle array of types (e.g., ["Recipe", "HowTo"])
        if (Array.isArray(item["@type"]) && item["@type"].includes("Recipe")) {
          return item as JsonLdRecipe;
        }

        // Check @graph for Recipe (common in WordPress sites)
        if (item["@graph"] && Array.isArray(item["@graph"])) {
          const recipe = item["@graph"].find(
            (g: { "@type"?: string | string[] }) =>
              g["@type"] === "Recipe" ||
              (Array.isArray(g["@type"]) && g["@type"].includes("Recipe"))
          );
          if (recipe) return recipe as JsonLdRecipe;
        }
      }
    } catch {
      // Continue to next script tag if parsing fails
      continue;
    }
  }

  return null;
}

export function parseISODuration(duration: string | undefined): number | null {
  // Parse ISO 8601 duration (e.g., "PT30M", "PT1H30M", "P0DT0H30M")
  if (!duration) return null;

  const match = duration.match(/P(?:(\d+)D)?T?(?:(\d+)H)?(?:(\d+)M)?/);
  if (!match) return null;

  const days = parseInt(match[1] || "0", 10);
  const hours = parseInt(match[2] || "0", 10);
  const minutes = parseInt(match[3] || "0", 10);

  return days * 24 * 60 + hours * 60 + minutes;
}

export function extractAuthorName(author: JsonLdRecipe["author"]): string | null {
  if (!author) return null;
  if (typeof author === "string") return author;
  if (typeof author === "object" && author.name) return author.name;
  return null;
}

export function extractFirstString(value: string | string[] | undefined): string | null {
  if (!value) return null;
  if (typeof value === "string") return value;
  if (Array.isArray(value) && value.length > 0) return value[0];
  return null;
}
