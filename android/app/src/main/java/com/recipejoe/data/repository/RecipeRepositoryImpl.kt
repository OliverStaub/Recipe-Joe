package com.recipejoe.data.repository

import com.recipejoe.data.local.dao.RecipeDao
import com.recipejoe.data.local.entity.RecipeEntity
import com.recipejoe.data.remote.SupabaseClientProvider
import com.recipejoe.data.remote.dto.MediaImportRequest
import com.recipejoe.data.remote.dto.RecipeDto
import com.recipejoe.data.remote.dto.RecipeImportRequest
import com.recipejoe.data.remote.dto.RecipeImportResponse
import com.recipejoe.data.remote.dto.RecipeIngredientDto
import com.recipejoe.data.remote.dto.RecipeStepDto
import com.recipejoe.domain.model.ImportResult
import com.recipejoe.domain.model.MediaImportType
import com.recipejoe.domain.model.Recipe
import com.recipejoe.domain.model.RecipeDetail
import io.github.jan.supabase.functions.functions
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.storage.storage
import io.ktor.client.call.body
import io.ktor.http.Headers
import io.ktor.http.HttpHeaders
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import timber.log.Timber
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

interface RecipeRepository {
    fun getRecipes(): Flow<List<Recipe>>
    fun searchRecipes(query: String): Flow<List<Recipe>>
    fun getFavoriteRecipes(): Flow<List<Recipe>>
    suspend fun getRecipeById(id: UUID): Recipe?
    suspend fun getRecipeDetail(id: UUID): RecipeDetail?
    suspend fun refreshRecipes()
    suspend fun importRecipe(
        url: String,
        language: String,
        translate: Boolean,
        startTimestamp: String? = null,
        endTimestamp: String? = null
    ): ImportResult
    suspend fun importFromMedia(
        storagePaths: List<String>,
        mediaType: MediaImportType,
        language: String,
        translate: Boolean
    ): ImportResult
    suspend fun uploadTempFile(data: ByteArray, contentType: String, fileExtension: String): String
    suspend fun updateFavorite(id: UUID, isFavorite: Boolean)
    suspend fun updateRecipeName(id: UUID, name: String)
    suspend fun updateRecipeDescription(id: UUID, description: String?)
    suspend fun deleteRecipe(id: UUID)
    suspend fun uploadRecipeImage(imageData: ByteArray, recipeId: UUID): String
    suspend fun clearCache()
}

@Singleton
class RecipeRepositoryImpl @Inject constructor(
    private val supabaseProvider: SupabaseClientProvider,
    private val recipeDao: RecipeDao
) : RecipeRepository {

    private val client get() = supabaseProvider.client

    override fun getRecipes(): Flow<List<Recipe>> {
        return recipeDao.getAllRecipes().map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override fun searchRecipes(query: String): Flow<List<Recipe>> {
        return recipeDao.searchRecipes(query).map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override fun getFavoriteRecipes(): Flow<List<Recipe>> {
        return recipeDao.getFavoriteRecipes().map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override suspend fun getRecipeById(id: UUID): Recipe? {
        return recipeDao.getRecipeById(id.toString())?.toDomain()
    }

    override suspend fun getRecipeDetail(id: UUID): RecipeDetail? {
        return try {
            val recipeDto = client.postgrest
                .from("recipes")
                .select {
                    filter {
                        eq("id", id.toString())
                    }
                }
                .decodeSingle<RecipeDto>()

            val stepsDto = client.postgrest
                .from("recipe_steps")
                .select {
                    filter {
                        eq("recipe_id", id.toString())
                    }
                    order("step_number", ascending = true)
                }
                .decodeList<RecipeStepDto>()

            val ingredientsDto = client.postgrest
                .from("recipe_ingredients")
                .select(columns = io.github.jan.supabase.postgrest.query.Columns.raw("*, ingredient:ingredients(*), measurement_type:measurement_types(*)")) {
                    filter {
                        eq("recipe_id", id.toString())
                    }
                    order("display_order", ascending = true)
                }
                .decodeList<RecipeIngredientDto>()

            RecipeDetail(
                recipe = recipeDto.toDomain(),
                steps = stepsDto.map { it.toDomain() },
                ingredients = ingredientsDto.map { it.toDomain() }
            )
        } catch (e: Exception) {
            Timber.e(e, "Failed to fetch recipe detail")
            null
        }
    }

    override suspend fun refreshRecipes() {
        try {
            val recipesDto = client.postgrest
                .from("recipes")
                .select {
                    order("created_at", ascending = false)
                }
                .decodeList<RecipeDto>()

            val entities = recipesDto.map { dto ->
                RecipeEntity.fromDomain(dto.toDomain())
            }
            recipeDao.insertRecipes(entities)
        } catch (e: Exception) {
            Timber.e(e, "Failed to refresh recipes")
            throw e
        }
    }

    override suspend fun importRecipe(
        url: String,
        language: String,
        translate: Boolean,
        startTimestamp: String?,
        endTimestamp: String?
    ): ImportResult {
        val request = RecipeImportRequest(
            url = url,
            language = language,
            translate = translate,
            startTimestamp = startTimestamp,
            endTimestamp = endTimestamp
        )

        val response = client.functions.invoke(
            function = "recipe-import",
            body = request
        )

        val result = response.body<RecipeImportResponse>()
        return result.toDomain()
    }

    override suspend fun importFromMedia(
        storagePaths: List<String>,
        mediaType: MediaImportType,
        language: String,
        translate: Boolean
    ): ImportResult {
        val request = MediaImportRequest(
            storagePaths = storagePaths,
            mediaType = mediaType.value,
            language = language,
            translate = translate
        )

        val response = client.functions.invoke(
            function = "recipe-ocr-import",
            body = request
        )

        val result = response.body<RecipeImportResponse>()
        return result.toDomain()
    }

    override suspend fun uploadTempFile(
        data: ByteArray,
        contentType: String,
        fileExtension: String
    ): String {
        val fileName = "${UUID.randomUUID()}.$fileExtension"
        val filePath = "temp/$fileName"

        client.storage.from("recipe-imports").upload(
            path = filePath,
            data = data,
            options = {
                this.contentType = contentType
                this.upsert = false
            }
        )

        return filePath
    }

    override suspend fun updateFavorite(id: UUID, isFavorite: Boolean) {
        client.postgrest
            .from("recipes")
            .update(mapOf("is_favorite" to isFavorite)) {
                filter {
                    eq("id", id.toString())
                }
            }
        recipeDao.updateFavorite(id.toString(), isFavorite)
    }

    override suspend fun updateRecipeName(id: UUID, name: String) {
        client.postgrest
            .from("recipes")
            .update(mapOf("name" to name)) {
                filter {
                    eq("id", id.toString())
                }
            }
    }

    override suspend fun updateRecipeDescription(id: UUID, description: String?) {
        client.postgrest
            .from("recipes")
            .update(mapOf("description" to description)) {
                filter {
                    eq("id", id.toString())
                }
            }
    }

    override suspend fun deleteRecipe(id: UUID) {
        client.postgrest
            .from("recipes")
            .delete {
                filter {
                    eq("id", id.toString())
                }
            }
        recipeDao.deleteRecipe(id.toString())
    }

    override suspend fun uploadRecipeImage(imageData: ByteArray, recipeId: UUID): String {
        val fileName = "$recipeId.jpg"

        client.storage.from("recipe-images").upload(
            path = fileName,
            data = imageData,
            options = {
                this.contentType = "image/jpeg"
                this.upsert = true
            }
        )

        val publicUrl = client.storage.from("recipe-images").publicUrl(fileName)

        // Update the recipe with the image URL
        client.postgrest
            .from("recipes")
            .update(mapOf("image_url" to publicUrl)) {
                filter {
                    eq("id", recipeId.toString())
                }
            }

        return publicUrl
    }

    override suspend fun clearCache() {
        recipeDao.clearAll()
    }
}
