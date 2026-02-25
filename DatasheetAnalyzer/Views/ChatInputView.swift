//
//  ChatInputView.swift
//  DatasheetAnalyzer
//
//  Created by Gavin Zyonse on 2/25/26.
//

import SwiftUI

/// Input field for sending chat messages
struct ChatInputView: View {
    @Binding var text: String
    let isDisabled: Bool
    let isProcessing: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Ask about the datasheet...", text: $text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(isDisabled || isProcessing)
                .onSubmit {
                    if !text.isEmpty && !isProcessing {
                        onSend()
                    }
                }
            
            Button(action: onSend) {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(text.isEmpty || isDisabled ? .secondary : .accentColor)
            .disabled(text.isEmpty || isDisabled || isProcessing)
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

#Preview {
    VStack {
        ChatInputView(
            text: .constant(""),
            isDisabled: false,
            isProcessing: false,
            onSend: {}
        )
        ChatInputView(
            text: .constant("What's the max voltage?"),
            isDisabled: false,
            isProcessing: false,
            onSend: {}
        )
        ChatInputView(
            text: .constant("Processing..."),
            isDisabled: false,
            isProcessing: true,
            onSend: {}
        )
    }
}
