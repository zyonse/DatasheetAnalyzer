//
//  PDFExtractor.swift
//  DatasheetAnalyzer
//
//  Created by Gavin Zyonse on 2/25/26.
//

import Foundation
import PDFKit

/// Service for extracting text content from PDF documents
class PDFExtractor {
    
    enum ExtractionError: Error, LocalizedError {
        case fileNotFound
        case invalidPDF
        case extractionFailed
        case emptyDocument
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "The PDF file could not be found."
            case .invalidPDF:
                return "The file is not a valid PDF document."
            case .extractionFailed:
                return "Failed to extract text from the PDF."
            case .emptyDocument:
                return "The PDF document appears to be empty or contains no extractable text."
            }
        }
    }
    
    /// Extract text from a PDF file at the given URL
    /// - Parameter url: The file URL of the PDF document
    /// - Returns: A tuple containing the extracted text and page count
    func extractText(from url: URL) throws -> (text: String, pageCount: Int) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ExtractionError.fileNotFound
        }
        
        guard let document = PDFDocument(url: url) else {
            throw ExtractionError.invalidPDF
        }
        
        let pageCount = document.pageCount
        guard pageCount > 0 else {
            throw ExtractionError.emptyDocument
        }
        
        var extractedText = ""
        
        for pageIndex in 0..<pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            if let pageText = page.string {
                extractedText += "--- Page \(pageIndex + 1) ---\n"
                extractedText += pageText
                extractedText += "\n\n"
            }
        }
        
        guard !extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ExtractionError.emptyDocument
        }
        
        return (extractedText, pageCount)
    }
    
    /// Create a Datasheet object from a PDF URL
    /// - Parameter url: The file URL of the PDF document
    /// - Returns: A Datasheet object with extracted content
    func createDatasheet(from url: URL) throws -> Datasheet {
        let (text, pageCount) = try extractText(from: url)
        let name = url.deletingPathExtension().lastPathComponent
        
        return Datasheet(
            name: name,
            url: url,
            extractedText: text,
            pageCount: pageCount
        )
    }
}
