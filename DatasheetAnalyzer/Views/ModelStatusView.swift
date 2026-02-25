//
//  ModelStatusView.swift
//  DatasheetAnalyzer
//
//  Created by Gavin Zyonse on 2/25/26.
//

import SwiftUI

/// View showing the status of the Apple Intelligence model
struct ModelStatusView: View {
    let availability: DatasheetAnalyzerService.ModelAvailability
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch availability {
        case .available:
            return .green
        case .checking:
            return .yellow
        case .unavailable:
            return .red
        }
    }
    
    private var statusText: String {
        switch availability {
        case .available:
            return "Apple Intelligence Ready"
        case .checking:
            return "Checking model..."
        case .unavailable(let reason):
            return reason
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ModelStatusView(availability: .available)
        ModelStatusView(availability: .checking)
        ModelStatusView(availability: .unavailable("Model not available"))
    }
    .padding()
}
