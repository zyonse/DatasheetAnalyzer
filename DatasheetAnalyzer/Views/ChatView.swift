//
//  ChatView.swift
//  DatasheetAnalyzer
//
//  Created by Gavin Zyonse on 2/25/26.
//

import SwiftUI

/// Main chat interface for interacting with datasheets
struct ChatView: View {
    @ObservedObject var viewModel: DatasheetViewModel
    @State private var inputText = ""
    @State private var scrollProxy: ScrollViewProxy?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            if let datasheet = viewModel.selectedDatasheet {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(datasheet.name)
                            .font(.headline)
                        Text("\(datasheet.pageCount) pages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { viewModel.clearChat() }) {
                        Label("Clear Chat", systemImage: "trash")
                    }
                    .buttonStyle(.borderless)
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor))
                
                Divider()
            }
            
            // Messages
            if viewModel.selectedDatasheet != nil {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.chatMessages) { message in
                                ChatBubbleView(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                    .onChange(of: viewModel.chatMessages.count) { _, _ in
                        if let lastMessage = viewModel.chatMessages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Datasheet Selected")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Import a PDF datasheet to start asking questions")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Input
            if viewModel.selectedDatasheet != nil {
                Divider()
                ChatInputView(
                    text: $inputText,
                    isDisabled: viewModel.selectedDatasheet == nil,
                    isProcessing: viewModel.analyzerService.isProcessing,
                    onSend: sendMessage
                )
            }
        }
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        inputText = ""
        
        Task {
            await viewModel.sendMessage(text)
        }
    }
}

#Preview {
    ChatView(viewModel: DatasheetViewModel())
        .frame(width: 500, height: 600)
}
