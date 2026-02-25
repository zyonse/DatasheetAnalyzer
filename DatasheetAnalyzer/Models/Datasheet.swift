//
//  Datasheet.swift
//  DatasheetAnalyzer
//
//  Created by Gavin Zyonse on 2/25/26.
//

import Foundation

/// Represents an imported PDF datasheet
struct Datasheet: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    let extractedText: String
    let pageCount: Int
    let importDate: Date
    
    init(name: String, url: URL, extractedText: String, pageCount: Int, importDate: Date = Date()) {
        self.name = name
        self.url = url
        self.extractedText = extractedText
        self.pageCount = pageCount
        self.importDate = importDate
    }
    
    /// Get a truncated preview of the extracted text
    var textPreview: String {
        let maxLength = 200
        if extractedText.count > maxLength {
            return String(extractedText.prefix(maxLength)) + "..."
        }
        return extractedText
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Datasheet, rhs: Datasheet) -> Bool {
        lhs.id == rhs.id
    }
}
