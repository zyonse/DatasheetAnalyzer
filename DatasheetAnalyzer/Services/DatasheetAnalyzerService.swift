//
//  DatasheetAnalyzerService.swift
//  DatasheetAnalyzer
//
//  Created by Gavin Zyonse on 2/25/26.
//

import Foundation
import FoundationModels
import Combine

/// Tool for the foundation model to perform keyword searches on the datasheet
struct KeywordSearchTool: Tool {
    let datasheetText: String
    
    var description: String {
        "Search the datasheet for instances of a specific keyword to find relevant information over the whole document."
    }
    
    @Generable
    struct Arguments {
        let keyword: String
    }
    
    func call(arguments: Arguments) async throws -> String {
        let keyword = arguments.keyword
        let text = datasheetText
        
        guard !keyword.isEmpty, text.localizedCaseInsensitiveContains(keyword) else {
            return "No occurrences of '\(keyword)' found in the datasheet."
        }
        
        var results: [String] = []
        let nsText = text as NSString
        var searchRange = NSRange(location: 0, length: nsText.length)
        let contextSize = 500 // Reduce context size to fit in context window and avoid contextTooLarge Error
        let maxResults = 3 // Reduce max results
        
        while searchRange.location < nsText.length {
            let matchRange = nsText.range(of: keyword, options: .caseInsensitive, range: searchRange)
            if matchRange.location != NSNotFound {
                let start = max(0, matchRange.location - contextSize)
                let end = min(nsText.length, matchRange.location + matchRange.length + contextSize)
                let contextRange = NSRange(location: start, length: end - start)
                let context = nsText.substring(with: contextRange)
                results.append("... \(context) ...")
                
                searchRange = NSRange(location: matchRange.location + matchRange.length, length: nsText.length - (matchRange.location + matchRange.length))
                if results.count >= maxResults { break }
            } else {
                break
            }
        }
        
        return results.joined(separator: "\n\n---\n\n")
    }
}

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
        
        currentDatasheetContext = datasheet.extractedText
        
        let instructions = """
        You are a helpful technical assistant specialized in analyzing electronic component datasheets.
        You have been provided with a tool to keyword search the full contents of the datasheet. 
        Use the `KeywordSearchTool` to reliably retrieve specifications, pinouts, and application details before answering.
        Do NOT assume or halluncinate information without searching for it first.
        Answer questions about this datasheet accurately and concisely. When referencing specifications, include the exact values from the datasheet.
        Respond in plain text only. Do not use Markdown formatting, including bold, italics, bullet lists,
        numbered lists, code fences, or other markup.
        
        Focus on:
        - Electrical specifications (voltage limits, current ratings, power consumption)
        - Pin configurations and pinouts
        - Operating conditions and absolute maximum ratings
        - Timing specifications
        - Package information
        - Application circuit recommendations
        
        If you cannot find the requested information even after searching, say so clearly.
        Always be precise with numbers and units.
        """
        
        let searchTool = KeywordSearchTool(datasheetText: datasheet.extractedText)
        
        session = LanguageModelSession(
            tools: [searchTool],
            instructions: Instructions(instructions)
        )
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
