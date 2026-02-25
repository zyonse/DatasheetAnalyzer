//
//  DatasheetViewModel.swift
//  DatasheetAnalyzer
//
//  Created by Gavin Zyonse on 2/25/26.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Combine

/// Main view model for managing datasheets and chat interactions
@MainActor
class DatasheetViewModel: ObservableObject {
    @Published var datasheets: [Datasheet] = []
    @Published var selectedDatasheet: Datasheet?
    @Published var chatMessages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let pdfExtractor = PDFExtractor()
    let analyzerService = DatasheetAnalyzerService()
    
    /// Import a PDF file from the given URL
    func importPDF(from url: URL) {
        isLoading = true
        errorMessage = nil
        
        // Ensure we have access to the file
        guard url.startAccessingSecurityScopedResource() else {
            showError(message: "Could not access the selected file. Please try again.")
            isLoading = false
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let datasheet = try pdfExtractor.createDatasheet(from: url)
            
            // Check if already imported
            if datasheets.contains(where: { $0.url == url }) {
                showError(message: "This datasheet has already been imported.")
                isLoading = false
                return
            }
            
            datasheets.append(datasheet)
            selectDatasheet(datasheet)
            
        } catch {
            showError(message: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    /// Import a PDF from dropped file data
    func importDroppedPDF(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        
        isLoading = true
        
        provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { [weak self] item, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.showError(message: "Failed to load dropped file: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }
                
                if let url = item as? URL {
                    self.importPDF(from: url)
                } else if let data = item as? Data {
                    // Handle data directly
                    self.importPDFData(data, name: "Dropped Datasheet")
                } else {
                    self.showError(message: "Could not read the dropped file.")
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Import PDF from raw data
    private func importPDFData(_ data: Data, name: String) {
        // Create a temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf")
        
        do {
            try data.write(to: tempURL)
            let datasheet = try pdfExtractor.createDatasheet(from: tempURL)
            datasheets.append(datasheet)
            selectDatasheet(datasheet)
            
            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)
        } catch {
            showError(message: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    /// Select a datasheet and set up the analyzer session
    func selectDatasheet(_ datasheet: Datasheet) {
        selectedDatasheet = datasheet
        chatMessages = []
        
        do {
            try analyzerService.setupSession(with: datasheet)
            
            // Add welcome message
            let welcomeMessage = ChatMessage(
                content: "I've loaded \"\(datasheet.name)\" (\(datasheet.pageCount) pages). Ask me anything about this datasheet - voltage limits, pinouts, specifications, and more!",
                isUser: false
            )
            chatMessages.append(welcomeMessage)
            
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    /// Send a question to the analyzer
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(content: text, isUser: true)
        chatMessages.append(userMessage)
        
        do {
            let response = try await analyzerService.askQuestion(text)
            let assistantMessage = ChatMessage(content: response, isUser: false)
            chatMessages.append(assistantMessage)
        } catch {
            let errorMessage = ChatMessage(
                content: "Sorry, I encountered an error: \(error.localizedDescription)",
                isUser: false
            )
            chatMessages.append(errorMessage)
        }
    }
    
    /// Remove a datasheet from the list
    func removeDatasheet(_ datasheet: Datasheet) {
        datasheets.removeAll { $0.id == datasheet.id }
        
        if selectedDatasheet?.id == datasheet.id {
            selectedDatasheet = datasheets.first
            if let selected = selectedDatasheet {
                selectDatasheet(selected)
            } else {
                chatMessages = []
                analyzerService.resetSession()
            }
        }
    }
    
    /// Clear chat history for current datasheet
    func clearChat() {
        guard let datasheet = selectedDatasheet else { return }
        selectDatasheet(datasheet) // This resets the chat with a welcome message
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
