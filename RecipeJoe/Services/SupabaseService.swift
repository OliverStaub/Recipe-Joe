//
//  SupabaseService.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 05.12.2025.
//

import Foundation
import Supabase

/// Service to interact with Supabase Edge Functions
@MainActor
final class SupabaseService {
    // MARK: - Singleton

    static let shared = SupabaseService()

    // MARK: - Properties

    private let client: SupabaseClient

    // MARK: - Configuration

    /// Supabase project URL - Replace with your actual project URL
    private static let supabaseURL = "REMOVED_URL"

    /// Supabase anon key - Safe to expose in client apps
    /// This key only allows access to public resources and Edge Functions
    private static let supabaseAnonKey = "REMOVED_KEY"

    // MARK: - Initialization

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: Self.supabaseURL)!,
            supabaseKey: Self.supabaseAnonKey
        )
    }

    // MARK: - Edge Function Calls

    /// Response structure from the anthropic-relay function
    struct AnthropicRelayResponse: Codable {
        let success: Bool
        let message: String?
        let model: String?
        let error: String?
    }

    /// Request structure for the anthropic-relay function
    struct AnthropicRelayRequest: Codable {
        let prompt: String
    }

    /// Call the anthropic-relay Edge Function
    /// - Parameter prompt: The prompt to send to Claude
    /// - Returns: The response message from Claude
    func callAnthropicRelay(prompt: String = "Hello! Please say hello back.") async throws -> String {
        let request = AnthropicRelayRequest(prompt: prompt)

        let response: AnthropicRelayResponse = try await client.functions.invoke(
            "anthropic-relay",
            options: FunctionInvokeOptions(body: request)
        )

        if response.success, let message = response.message {
            return message
        } else if let error = response.error {
            throw SupabaseError.functionError(error)
        } else {
            throw SupabaseError.unknownError
        }
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case functionError(String)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .functionError(let message):
            return "Function error: \(message)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}
