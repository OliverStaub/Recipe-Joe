package com.recipejoe.data.remote

import com.recipejoe.BuildConfig
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.functions.Functions
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.storage.Storage
import io.ktor.client.HttpClient
import io.ktor.client.engine.android.Android
import io.ktor.client.plugins.HttpTimeout
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SupabaseClientProvider @Inject constructor() {
    val client: SupabaseClient = createSupabaseClient(
        supabaseUrl = BuildConfig.SUPABASE_URL,
        supabaseKey = BuildConfig.SUPABASE_ANON_KEY
    ) {
        // Configure HTTP client with extended timeouts for long-running operations
        // Recipe imports can take several minutes for video transcription
        httpEngine = Android.create {
            connectTimeout = 30_000  // 30 seconds for connection
            socketTimeout = 600_000  // 10 minutes for read/write (video imports)
        }

        install(Auth)
        install(Postgrest)
        install(Storage)
        install(Functions)
    }
}
