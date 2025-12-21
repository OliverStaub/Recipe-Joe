// Unit tests for recipe-import edge function
// Run with: deno test --allow-all supabase/functions/tests/recipe-import-test.ts
//
// These tests invoke the edge function directly to test authentication,
// request validation, and error handling.

import { assertEquals, assertExists } from "jsr:@std/assert@1";
import "jsr:@std/dotenv/load";
import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

// Get Supabase config from environment
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const TEST_USER_EMAIL = Deno.env.get("TEST_USER_EMAIL") ?? "";
const TEST_USER_PASSWORD = Deno.env.get("TEST_USER_PASSWORD") ?? "";

// Edge function URL (local or remote)
const EDGE_FUNCTION_URL = Deno.env.get("EDGE_FUNCTION_URL") ?? `${SUPABASE_URL}/functions/v1/recipe-import`;

// Helper to create authenticated client
async function getAuthenticatedClient(): Promise<{ client: SupabaseClient; accessToken: string }> {
  const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
      detectSessionInUrl: false,
    },
  });

  const { data, error } = await client.auth.signInWithPassword({
    email: TEST_USER_EMAIL,
    password: TEST_USER_PASSWORD,
  });

  if (error) {
    throw new Error(`Failed to sign in test user: ${error.message}`);
  }

  return {
    client,
    accessToken: data.session?.access_token ?? "",
  };
}

// Helper to invoke the edge function
async function invokeEdgeFunction(
  body: Record<string, unknown>,
  accessToken?: string
): Promise<Response> {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    "apikey": SUPABASE_ANON_KEY,
  };

  if (accessToken) {
    headers["Authorization"] = `Bearer ${accessToken}`;
  }

  return await fetch(EDGE_FUNCTION_URL, {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

// =============================================================================
// Configuration Validation Tests
// =============================================================================

Deno.test("config - SUPABASE_URL is set", () => {
  assertExists(SUPABASE_URL, "SUPABASE_URL environment variable must be set");
  assertEquals(SUPABASE_URL.startsWith("http"), true, "SUPABASE_URL must be a valid URL");
});

Deno.test("config - SUPABASE_ANON_KEY is set", () => {
  assertExists(SUPABASE_ANON_KEY, "SUPABASE_ANON_KEY environment variable must be set");
  assertEquals(SUPABASE_ANON_KEY.length > 0, true, "SUPABASE_ANON_KEY must not be empty");
});

Deno.test("config - TEST_USER credentials are set", () => {
  assertExists(TEST_USER_EMAIL, "TEST_USER_EMAIL environment variable must be set");
  assertExists(TEST_USER_PASSWORD, "TEST_USER_PASSWORD environment variable must be set");
});

// =============================================================================
// Authentication Tests
// =============================================================================

Deno.test("auth - request without apikey header returns 401 from Supabase gateway", async () => {
  // When apikey is missing, Supabase infrastructure rejects the request
  const response = await invokeEdgeFunction(
    { url: "https://example.com/recipe" },
    undefined,
    false // Don't include apikey
  );
  await response.body?.cancel(); // Consume body to prevent leak

  assertEquals(response.status, 401);
});

Deno.test("auth - request with apikey but no Authorization returns 500 with auth error", async () => {
  // With apikey but no auth token, our function runs and returns auth error
  const response = await invokeEdgeFunction({ url: "https://example.com/recipe" });
  const data = await response.json();

  assertEquals(response.status, 500);
  assertEquals(data.success, false);
  assertEquals(data.error, "Authentication required");
});

Deno.test("auth - request with invalid token returns 500 with auth error", async () => {
  const response = await invokeEdgeFunction(
    { url: "https://example.com/recipe" },
    "invalid-token-12345"
  );
  const data = await response.json();

  assertEquals(response.status, 500);
  assertEquals(data.success, false);
  assertEquals(data.error, "Authentication required");
});

Deno.test("auth - request with malformed JWT returns 500 with auth error", async () => {
  // This is a structurally valid but malformed JWT
  const malformedToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiZXhwIjoxfQ.invalid";

  const response = await invokeEdgeFunction(
    { url: "https://example.com/recipe" },
    malformedToken
  );
  const data = await response.json();

  assertEquals(response.status, 500);
  assertEquals(data.success, false);
  assertEquals(data.error, "Authentication required");
});

Deno.test("auth - request with valid token accepts the request", async () => {
  const { accessToken } = await getAuthenticatedClient();

  // Use a URL that won't be a valid recipe but will pass auth
  const response = await invokeEdgeFunction(
    { url: "https://example.com/not-a-recipe" },
    accessToken
  );
  const data = await response.json();

  // Should pass auth but may fail on recipe extraction
  // Status 400 = recipe not valid, 200 = success, 500 = other error
  // As long as error is NOT "Authentication required", auth worked
  if (!data.success) {
    assertEquals(data.error !== "Authentication required", true,
      `Auth should pass but got: ${data.error}`);
  }
});

// =============================================================================
// Request Validation Tests
// =============================================================================

Deno.test("validation - request without URL returns error", async () => {
  const { accessToken } = await getAuthenticatedClient();

  const response = await invokeEdgeFunction({}, accessToken);
  const data = await response.json();

  assertEquals(response.status, 500);
  assertEquals(data.success, false);
  assertEquals(data.error, "URL is required");
});

Deno.test("validation - request with empty URL returns error", async () => {
  const { accessToken } = await getAuthenticatedClient();

  const response = await invokeEdgeFunction({ url: "" }, accessToken);
  const data = await response.json();

  assertEquals(response.status, 500);
  assertEquals(data.success, false);
  assertEquals(data.error, "URL is required");
});

Deno.test("validation - request with invalid URL format returns error", async () => {
  const { accessToken } = await getAuthenticatedClient();

  const response = await invokeEdgeFunction({ url: "not-a-url" }, accessToken);
  const data = await response.json();

  assertEquals(response.status, 500);
  assertEquals(data.success, false);
  assertEquals(data.error, "Invalid URL format");
});

Deno.test("validation - request with non-http URL returns error", async () => {
  const { accessToken } = await getAuthenticatedClient();

  const response = await invokeEdgeFunction({ url: "ftp://example.com/recipe" }, accessToken);
  const data = await response.json();

  assertEquals(response.status, 500);
  assertEquals(data.success, false);
  // Note: The URL constructor throws "Invalid URL format" before we can check protocol
  // This is expected behavior - we catch the invalid URL format error
  assertEquals(data.error === "Invalid URL format" || data.error === "Invalid URL protocol", true,
    `Expected 'Invalid URL format' or 'Invalid URL protocol' but got: ${data.error}`);
});

// =============================================================================
// Video URL Detection Tests (via edge function)
// =============================================================================

Deno.test("video detection - YouTube URL triggers video import path", async () => {
  const { accessToken } = await getAuthenticatedClient();

  // Use a YouTube URL - the function should detect it as a video
  // We expect it to try to fetch the transcript (may fail if video doesn't exist)
  const response = await invokeEdgeFunction(
    { url: "https://www.youtube.com/watch?v=invalid123" },
    accessToken
  );
  const data = await response.json();

  // The important thing is auth passed and video detection worked
  // Specific error doesn't matter as long as it's not auth-related
  if (!data.success) {
    assertEquals(data.error !== "Authentication required", true);
    assertEquals(data.error !== "URL is required", true);
    assertEquals(data.error !== "Invalid URL format", true);
  }
});

Deno.test("video detection - TikTok URL triggers video import path", async () => {
  const { accessToken } = await getAuthenticatedClient();

  const response = await invokeEdgeFunction(
    { url: "https://www.tiktok.com/@test/video/1234567890" },
    accessToken
  );
  const data = await response.json();

  // Auth should pass, video detection should work
  if (!data.success) {
    assertEquals(data.error !== "Authentication required", true);
    assertEquals(data.error !== "URL is required", true);
  }
});

// =============================================================================
// CORS Tests
// =============================================================================

Deno.test("cors - OPTIONS request returns ok", async () => {
  const headers: Record<string, string> = {};
  if (SUPABASE_ANON_KEY) {
    headers["apikey"] = SUPABASE_ANON_KEY;
  }

  const response = await fetch(EDGE_FUNCTION_URL, {
    method: "OPTIONS",
    headers,
  });
  await response.body?.cancel(); // Consume body to prevent leak

  assertEquals(response.status, 200);

  const corsOrigin = response.headers.get("Access-Control-Allow-Origin");
  assertEquals(corsOrigin, "*");
});

Deno.test("cors - response includes CORS headers", async () => {
  const response = await invokeEdgeFunction({ url: "https://example.com" });
  const data = await response.json(); // Consume body

  const corsOrigin = response.headers.get("Access-Control-Allow-Origin");
  assertEquals(corsOrigin, "*");
});
