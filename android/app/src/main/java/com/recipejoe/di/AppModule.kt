package com.recipejoe.di

import android.content.Context
import androidx.room.Room
import com.recipejoe.data.local.RecipeDatabase
import com.recipejoe.data.local.dao.RecipeDao
import com.recipejoe.data.remote.SupabaseClientProvider
import com.recipejoe.data.repository.AuthRepository
import com.recipejoe.data.repository.AuthRepositoryImpl
import com.recipejoe.data.repository.RecipeRepository
import com.recipejoe.data.repository.RecipeRepositoryImpl
import com.recipejoe.data.repository.TokenRepository
import com.recipejoe.data.repository.TokenRepositoryImpl
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideSupabaseClient(): SupabaseClientProvider {
        return SupabaseClientProvider()
    }

    @Provides
    @Singleton
    fun provideRecipeDatabase(
        @ApplicationContext context: Context
    ): RecipeDatabase {
        return Room.databaseBuilder(
            context,
            RecipeDatabase::class.java,
            "recipejoe.db"
        ).build()
    }

    @Provides
    @Singleton
    fun provideRecipeDao(database: RecipeDatabase): RecipeDao {
        return database.recipeDao()
    }

    @Provides
    @Singleton
    fun provideRecipeRepository(
        supabaseProvider: SupabaseClientProvider,
        recipeDao: RecipeDao
    ): RecipeRepository {
        return RecipeRepositoryImpl(supabaseProvider, recipeDao)
    }

    @Provides
    @Singleton
    fun provideAuthRepository(
        supabaseProvider: SupabaseClientProvider
    ): AuthRepository {
        return AuthRepositoryImpl(supabaseProvider)
    }

    @Provides
    @Singleton
    fun provideTokenRepository(
        supabaseProvider: SupabaseClientProvider
    ): TokenRepository {
        return TokenRepositoryImpl(supabaseProvider)
    }
}
