//
//  ChatBubbleView.swift
//  DatasheetAnalyzer
//
//  Created by Gavin Zyonse on 2/25/26.
//

import SwiftUI

/// A chat bubble view for displaying messages
struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isUser ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ChatBubbleView(message: ChatMessage(content: "What are the voltage limits?", isUser: true))
        ChatBubbleView(message: ChatMessage(content: "The absolute maximum voltage rating is 5.5V on VCC, with a recommended operating range of 3.3V to 5.0V.", isUser: false))
    }
    .padding()
    .frame(width: 400)
}
