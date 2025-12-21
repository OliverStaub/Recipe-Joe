// Unit tests for video-detector.ts utilities
// Run with: deno test --allow-all supabase/functions/tests/video-detector-test.ts

import { assertEquals, assertStrictEquals } from "jsr:@std/assert@1";
import {
  isVideoUrl,
  getVideoPlatform,
  extractVideoId,
  parseTimestamp,
  getNormalizedVideoUrl,
} from "../recipe-import/utils/video-detector.ts";

// =============================================================================
// isVideoUrl Tests
// =============================================================================

Deno.test("isVideoUrl - YouTube watch URL", () => {
  assertEquals(isVideoUrl("https://www.youtube.com/watch?v=dQw4w9WgXcQ"), true);
});

Deno.test("isVideoUrl - YouTube shorts URL", () => {
  assertEquals(isVideoUrl("https://youtube.com/shorts/abc123def45"), true);
});

Deno.test("isVideoUrl - YouTube short URL (youtu.be)", () => {
  assertEquals(isVideoUrl("https://youtu.be/dQw4w9WgXcQ"), true);
});

Deno.test("isVideoUrl - TikTok video URL", () => {
  assertEquals(isVideoUrl("https://www.tiktok.com/@chef/video/1234567890"), true);
});

Deno.test("isVideoUrl - TikTok short URL", () => {
  assertEquals(isVideoUrl("https://vm.tiktok.com/abc123"), true);
});

Deno.test("isVideoUrl - Instagram reel URL", () => {
  assertEquals(isVideoUrl("https://www.instagram.com/reel/abc123/"), true);
});

Deno.test("isVideoUrl - regular recipe URL returns false", () => {
  assertEquals(isVideoUrl("https://www.allrecipes.com/recipe/12345"), false);
});

Deno.test("isVideoUrl - empty URL returns false", () => {
  assertEquals(isVideoUrl(""), false);
});

Deno.test("isVideoUrl - non-video site returns false", () => {
  assertEquals(isVideoUrl("https://www.google.com"), false);
});

// =============================================================================
// getVideoPlatform Tests
// =============================================================================

Deno.test("getVideoPlatform - YouTube watch URL", () => {
  assertEquals(getVideoPlatform("https://www.youtube.com/watch?v=dQw4w9WgXcQ"), "youtube");
});

Deno.test("getVideoPlatform - YouTube shorts", () => {
  assertEquals(getVideoPlatform("https://youtube.com/shorts/abc123def45"), "youtube");
});

Deno.test("getVideoPlatform - TikTok", () => {
  assertEquals(getVideoPlatform("https://www.tiktok.com/@chef/video/1234567890"), "tiktok");
});

Deno.test("getVideoPlatform - Instagram", () => {
  assertEquals(getVideoPlatform("https://www.instagram.com/reel/abc123/"), "instagram");
});

Deno.test("getVideoPlatform - non-video returns null", () => {
  assertEquals(getVideoPlatform("https://www.example.com"), null);
});

// =============================================================================
// extractVideoId Tests
// =============================================================================

Deno.test("extractVideoId - YouTube watch URL", () => {
  assertEquals(extractVideoId("https://www.youtube.com/watch?v=dQw4w9WgXcQ"), "dQw4w9WgXcQ");
});

Deno.test("extractVideoId - YouTube watch URL with additional params", () => {
  assertEquals(extractVideoId("https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30"), "dQw4w9WgXcQ");
});

Deno.test("extractVideoId - YouTube shorts", () => {
  assertEquals(extractVideoId("https://youtube.com/shorts/abc123def45"), "abc123def45");
});

Deno.test("extractVideoId - youtu.be short URL", () => {
  assertEquals(extractVideoId("https://youtu.be/dQw4w9WgXcQ"), "dQw4w9WgXcQ");
});

Deno.test("extractVideoId - TikTok video URL", () => {
  assertEquals(extractVideoId("https://www.tiktok.com/@chef/video/7402633952399199521"), "7402633952399199521");
});

Deno.test("extractVideoId - TikTok short URL", () => {
  assertEquals(extractVideoId("https://vm.tiktok.com/abc123"), "abc123");
});

Deno.test("extractVideoId - Instagram reel", () => {
  assertEquals(extractVideoId("https://www.instagram.com/reel/CyXaBcD123/"), "CyXaBcD123");
});

Deno.test("extractVideoId - non-video URL returns null", () => {
  assertEquals(extractVideoId("https://www.google.com"), null);
});

// =============================================================================
// parseTimestamp Tests
// =============================================================================

Deno.test("parseTimestamp - MM:SS format", () => {
  assertEquals(parseTimestamp("1:30"), 90000); // 90 seconds in ms
});

Deno.test("parseTimestamp - MM:SS with zero padding", () => {
  assertEquals(parseTimestamp("01:05"), 65000); // 65 seconds in ms
});

Deno.test("parseTimestamp - HH:MM:SS format", () => {
  assertEquals(parseTimestamp("1:30:00"), 5400000); // 1.5 hours in ms
});

Deno.test("parseTimestamp - zero timestamp", () => {
  assertEquals(parseTimestamp("0:00"), 0);
});

Deno.test("parseTimestamp - empty string returns null", () => {
  assertEquals(parseTimestamp(""), null);
});

Deno.test("parseTimestamp - whitespace only returns null", () => {
  assertEquals(parseTimestamp("   "), null);
});

Deno.test("parseTimestamp - invalid format returns null", () => {
  assertEquals(parseTimestamp("invalid"), null);
});

Deno.test("parseTimestamp - negative minutes returns null", () => {
  assertEquals(parseTimestamp("-1:30"), null);
});

Deno.test("parseTimestamp - seconds >= 60 returns null", () => {
  assertEquals(parseTimestamp("1:60"), null);
});

Deno.test("parseTimestamp - handles whitespace", () => {
  assertEquals(parseTimestamp("  1:30  "), 90000);
});

// =============================================================================
// getNormalizedVideoUrl Tests
// =============================================================================

Deno.test("getNormalizedVideoUrl - YouTube normalizes to watch URL", () => {
  assertEquals(
    getNormalizedVideoUrl("https://youtu.be/abc", "youtube", "abc123def45"),
    "https://www.youtube.com/watch?v=abc123def45"
  );
});

Deno.test("getNormalizedVideoUrl - Instagram normalizes to reel URL", () => {
  assertEquals(
    getNormalizedVideoUrl("https://instagram.com/p/abc/", "instagram", "abc123"),
    "https://www.instagram.com/reel/abc123/"
  );
});

Deno.test("getNormalizedVideoUrl - TikTok keeps original URL", () => {
  const originalUrl = "https://www.tiktok.com/@chef/video/1234567890";
  assertEquals(
    getNormalizedVideoUrl(originalUrl, "tiktok", "1234567890"),
    originalUrl
  );
});
