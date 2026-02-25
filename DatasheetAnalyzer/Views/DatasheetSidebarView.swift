//
//  DatasheetSidebarView.swift
//  DatasheetAnalyzer
//
//  Created by Gavin Zyonse on 2/25/26.
//

import SwiftUI
import UniformTypeIdentifiers

/// Sidebar showing imported datasheets
struct DatasheetSidebarView: View {
    @ObservedObject var viewModel: DatasheetViewModel
    @State private var isTargeted = false
    @State private var showFileImporter = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with import button
            HStack {
                Text("Datasheets")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showFileImporter = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Import PDF Datasheet")
            }
            .padding()
            
            Divider()
            
            // Datasheet list or drop zone
            if viewModel.datasheets.isEmpty {
                dropZone
            } else {
                List(selection: $viewModel.selectedDatasheet) {
                    ForEach(viewModel.datasheets) { datasheet in
                        DatasheetRowView(datasheet: datasheet)
                            .tag(datasheet)
                            .contextMenu {
                                Button(role: .destructive, action: { viewModel.removeDatasheet(datasheet) }) {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.sidebar)
                .onChange(of: viewModel.selectedDatasheet) { _, newValue in
                    if let datasheet = newValue {
                        viewModel.selectDatasheet(datasheet)
                    }
                }
            }
        }
        .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.importPDF(from: url)
                }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
                viewModel.showError = true
            }
        }
    }
    
    private var dropZone: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(isTargeted ? .accentColor : .secondary)
            
            Text("Drop PDF Here")
                .font(.headline)
                .foregroundColor(isTargeted ? .accentColor : .primary)
            
            Text("or click + to import")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .padding()
        )
        .onDrop(of: [.pdf], isTargeted: $isTargeted) { providers in
            viewModel.importDroppedPDF(providers: providers)
            return true
        }
    }
}

/// Row view for a single datasheet in the sidebar
struct DatasheetRowView: View {
    let datasheet: Datasheet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(datasheet.name)
                .font(.system(.body, weight: .medium))
                .lineLimit(1)
            
            HStack {
                Text("\(datasheet.pageCount) pages")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(datasheet.importDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DatasheetSidebarView(viewModel: DatasheetViewModel())
}
