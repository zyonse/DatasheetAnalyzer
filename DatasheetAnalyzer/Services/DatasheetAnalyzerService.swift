//
//  DatasheetAnalyzerService.swift
//  DatasheetAnalyzer
//
//  Created by Gavin Zyonse on 2/25/26.
//

import Foundation
import FoundationModels
import Combine

/// Service that interfaces with Apple's Foundation Model for datasheet Q&A
@MainActor
class DatasheetAnalyzerService: ObservableObject {
    
    enum ServiceError: Error, LocalizedError {
        case modelNotAvailable(String)
        case noDatasheetLoaded
        case generationFailed(String)
        case contextTooLarge
        
        var errorDescription: String? {
            switch self {
            case .modelNotAvailable(let reason):
                return "Apple Intelligence is not available: \(reason)"
            case .noDatasheetLoaded:
                return "Please load a datasheet first before asking questions."
            case .generationFailed(let message):
                return "Failed to generate response: \(message)"
            case .contextTooLarge:
                return "The datasheet is too large to process. Try asking about specific sections."
            }
        }
    }
    
    @Published var isProcessing = false
    @Published var modelAvailability: ModelAvailability = .checking
    
    private var session: LanguageModelSession?
    private var currentDatasheetContext: String?
    
    enum ModelAvailability: Equatable {
        case checking
        case available
        case unavailable(String)
    }
    
    init() {
        checkModelAvailability()
    }
    
    /// Check if the Foundation Model is available on this device
    func checkModelAvailability() {
        let model = SystemLanguageModel.default
        
        switch model.availability {
        case .available:
            modelAvailability = .available
        case .unavailable(.deviceNotEligible):
            modelAvailability = .unavailable("This device does not support Apple Intelligence.")
        case .unavailable(.appleIntelligenceNotEnabled):
            modelAvailability = .unavailable("Please enable Apple Intelligence in System Settings.")
        case .unavailable(.modelNotReady):
            modelAvailability = .unavailable("The model is still downloading. Please try again later.")
        case .unavailable:
            modelAvailability = .unavailable("Apple Intelligence is unavailable.")
        @unknown default:
            modelAvailability = .unavailable("Unknown availability status.")
        }
    }
    
    /// Set up a new session with the given datasheet context
    /// - Parameter datasheet: The datasheet to analyze
    func setupSession(with datasheet: Datasheet) throws {
        guard case .available = modelAvailability else {
            if case .unavailable(let reason) = modelAvailability {
                throw ServiceError.modelNotAvailable(reason)
            }
            throw ServiceError.modelNotAvailable("Model not ready")
        }
        
        // Truncate the datasheet text if it's too long for the context window
        // The model supports ~4096 tokens, roughly 3-4 chars per token
        // Leave room for instructions, prompts, and responses
        let maxContextChars = 8000
        var contextText = datasheet.extractedText
        if contextText.count > maxContextChars {
            contextText = String(contextText.prefix(maxContextChars)) + "\n\n[Text truncated due to length...]"
        }
        
        currentDatasheetContext = contextText
        
        let instructions = """
        You are a helpful technical assistant specialized in analyzing electronic component datasheets.
        You have been provided with the contents of a datasheet. Answer questions about this datasheet
        accurately and concisely. When referencing specifications, include the exact values from the datasheet.
        Respond in plain text only. Do not use Markdown formatting, including bold, italics, bullet lists,
        numbered lists, code fences, or other markup.
        
        Focus on:
        - Electrical specifications (voltage limits, current ratings, power consumption)
        - Pin configurations and pinouts
        - Operating conditions and absolute maximum ratings
        - Timing specifications
        - Package information
        - Application circuit recommendations
        
        If you cannot find the requested information in the provided datasheet content, say so clearly.
        Always be precise with numbers and units.
        
        DATASHEET CONTENT:
        \(contextText)
        """
        
        session = LanguageModelSession(instructions: Instructions(instructions))
    }
    
    /// Ask a question about the currently loaded datasheet
    /// - Parameter question: The user's question
    /// - Returns: The model's response
    func askQuestion(_ question: String) async throws -> String {
        guard let session = session else {
            throw ServiceError.noDatasheetLoaded
        }
        
        guard case .available = modelAvailability else {
            if case .unavailable(let reason) = modelAvailability {
                throw ServiceError.modelNotAvailable(reason)
            }
            throw ServiceError.modelNotAvailable("Model not ready")
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let response = try await session.respond(to: Prompt(question))
            return response.content
        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .exceededContextWindowSize:
                throw ServiceError.contextTooLarge
            default:
                throw ServiceError.generationFailed(error.localizedDescription)
            }
        } catch {
            throw ServiceError.generationFailed(error.localizedDescription)
        }
    }
    
    /// Reset the current session
    func resetSession() {
        session = nil
        currentDatasheetContext = nil
    }
}
