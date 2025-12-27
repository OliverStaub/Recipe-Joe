package com.recipejoe.domain.model

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class TokenBalanceTest {

    @Test
    fun `TokenPackage fromProductId returns correct package`() {
        assertEquals(TokenPackage.TOKENS_10, TokenPackage.fromProductId("tokens_10"))
        assertEquals(TokenPackage.TOKENS_25, TokenPackage.fromProductId("tokens_25"))
        assertEquals(TokenPackage.TOKENS_50, TokenPackage.fromProductId("tokens_50"))
        assertEquals(TokenPackage.TOKENS_120, TokenPackage.fromProductId("tokens_120"))
    }

    @Test
    fun `TokenPackage fromProductId returns null for unknown product`() {
        assertNull(TokenPackage.fromProductId("tokens_999"))
        assertNull(TokenPackage.fromProductId("invalid"))
        assertNull(TokenPackage.fromProductId(""))
    }

    @Test
    fun `TokenPackage has correct token counts`() {
        assertEquals(10, TokenPackage.TOKENS_10.tokenCount)
        assertEquals(25, TokenPackage.TOKENS_25.tokenCount)
        assertEquals(50, TokenPackage.TOKENS_50.tokenCount)
        assertEquals(120, TokenPackage.TOKENS_120.tokenCount)
    }

    @Test
    fun `TokenPackage has correct product IDs`() {
        assertEquals("tokens_10", TokenPackage.TOKENS_10.productId)
        assertEquals("tokens_25", TokenPackage.TOKENS_25.productId)
        assertEquals("tokens_50", TokenPackage.TOKENS_50.productId)
        assertEquals("tokens_120", TokenPackage.TOKENS_120.productId)
    }

    @Test
    fun `TokenBalance stores balance correctly`() {
        val balance = TokenBalance(balance = 42)
        assertEquals(42, balance.balance)
    }
}
