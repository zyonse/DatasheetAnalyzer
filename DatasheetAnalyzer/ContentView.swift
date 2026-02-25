//
//  ContentView.swift
//  DatasheetAnalyzer
//
//  Created by Gavin Zyonse on 2/25/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DatasheetViewModel()
    
    var body: some View {
        NavigationSplitView {
            DatasheetSidebarView(viewModel: viewModel)
        } detail: {
            ChatView(viewModel: viewModel)
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                ModelStatusView(availability: viewModel.analyzerService.modelAvailability)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
