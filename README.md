# DatasheetAnalyzer

DatasheetAnalyzer is a native macOS application designed to help engineers interactively analyze electronic component datasheets through natural language conversation. It combines local PDF extraction with on-device Large Language Models (Apple Intelligence) to allow fast, private querying of complex technical specifications.

## Code Structure

- **`DatasheetAnalyzerApp.swift`**: The main entry point of the application.
- **`ContentView.swift`**: The root view establishing the split-view layout (sidebar + chat).
- **`Models/`**:
  - `Datasheet.swift`: The data model representing a parsed datasheet, including metadata and textual content.
  - `ChatMessage.swift`: The data model representing individual questions and answers in a chat session.
- **`ViewModels/`**:
  - `DatasheetViewModel.swift`: The central state manager orchestrating PDF imports, active selections, and message routing.
- **`Services/`**:
  - `PDFExtractor.swift`: Service leveraging `PDFKit` to extract plain text and structural metadata from PDF files.
  - `DatasheetAnalyzerService.swift`: Service wrapper utilizing the FoundationModels framework to initialize `LanguageModelSession` and process user queries against the datasheet context.
- **`Views/`**:
  - `DatasheetSidebarView.swift`: UI for datasheet management, including drop zones and file selection.
  - `ChatView.swift`, `ChatBubbleView.swift`, `ChatInputView.swift`: UI components for the conversational interface.
  - `ModelStatusView.swift`: Simple indicator for Apple Intelligence availability.

## Dependencies

This project requires **macOS 15.0+** and **Xcode 16.0+** to compile and run.
It utilizes the following native Apple frameworks without any external third-party dependencies:
- **SwiftUI**: For declarative user interface construction.
- **FoundationModels**: For integrating with the local `SystemLanguageModel` (Apple Intelligence).
- **PDFKit**: For parsing and rendering PDF documents.
- **UniformTypeIdentifiers**: For document types handling during import.

## Instructions to Run

1. Open `DatasheetAnalyzer.xcodeproj` in Xcode 16 or later.
2. Ensure the active scheme is set to "My Mac" (or appropriate build target).
3. Build and run the project (`Cmd + R`).
4. In the running application, click "Import Datasheet" or drag and drop a PDF file into the sidebar.
5. Select the imported document and use the chat input field to ask questions about its contents.
