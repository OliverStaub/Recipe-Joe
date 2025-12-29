package com.recipejoe.data.repository

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.util.Locale
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "user_settings")

/**
 * Supported languages for app UI
 */
enum class AppLanguage(val code: String, val displayName: String, val flag: String) {
    SYSTEM("system", "System Default", "📱"),
    ENGLISH("en", "English", "🇬🇧"),
    GERMAN("de", "Deutsch", "🇩🇪"),
    SWISS_GERMAN("gsw", "Schwiizerdütsch", "🇨🇭");

    companion object {
        fun fromCode(code: String): AppLanguage =
            entries.find { it.code == code } ?: SYSTEM
    }
}

/**
 * Supported languages for recipe import
 */
enum class RecipeLanguage(val code: String, val displayName: String, val flag: String) {
    ENGLISH("en", "English", "🇬🇧"),
    GERMAN("de", "Deutsch", "🇩🇪");

    companion object {
        fun fromCode(code: String): RecipeLanguage =
            entries.find { it.code == code } ?: ENGLISH

        fun fromLocale(): RecipeLanguage {
            val deviceLanguage = Locale.getDefault().language
            return if (deviceLanguage == "de") GERMAN else ENGLISH
        }
    }
}

data class UserSettings(
    val appLanguage: AppLanguage = AppLanguage.SYSTEM,
    val recipeLanguage: RecipeLanguage = RecipeLanguage.fromLocale(),
    val enableTranslation: Boolean = true
)

interface UserSettingsRepository {
    val settings: Flow<UserSettings>
    suspend fun setAppLanguage(language: AppLanguage)
    suspend fun setRecipeLanguage(language: RecipeLanguage)
    suspend fun setEnableTranslation(enabled: Boolean)
}

@Singleton
class UserSettingsRepositoryImpl @Inject constructor(
    @ApplicationContext private val context: Context
) : UserSettingsRepository {

    private object PreferencesKeys {
        val APP_LANGUAGE = stringPreferencesKey("app_language")
        val RECIPE_LANGUAGE = stringPreferencesKey("recipe_language")
        val ENABLE_TRANSLATION = booleanPreferencesKey("enable_translation")
    }

    override val settings: Flow<UserSettings> = context.dataStore.data.map { preferences ->
        UserSettings(
            appLanguage = AppLanguage.fromCode(
                preferences[PreferencesKeys.APP_LANGUAGE] ?: AppLanguage.SYSTEM.code
            ),
            recipeLanguage = RecipeLanguage.fromCode(
                preferences[PreferencesKeys.RECIPE_LANGUAGE] ?: RecipeLanguage.fromLocale().code
            ),
            enableTranslation = preferences[PreferencesKeys.ENABLE_TRANSLATION] ?: true
        )
    }

    override suspend fun setAppLanguage(language: AppLanguage) {
        context.dataStore.edit { preferences ->
            preferences[PreferencesKeys.APP_LANGUAGE] = language.code
        }
    }

    override suspend fun setRecipeLanguage(language: RecipeLanguage) {
        context.dataStore.edit { preferences ->
            preferences[PreferencesKeys.RECIPE_LANGUAGE] = language.code
        }
    }

    override suspend fun setEnableTranslation(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[PreferencesKeys.ENABLE_TRANSLATION] = enabled
        }
    }
}
