package com.recipejoe.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.recipejoe.data.local.dao.RecipeDao
import com.recipejoe.data.local.entity.RecipeEntity

@Database(
    entities = [RecipeEntity::class],
    version = 1,
    exportSchema = true
)
abstract class RecipeDatabase : RoomDatabase() {
    abstract fun recipeDao(): RecipeDao
}
