import SwiftUI
import PencilKit
import CoreData

struct DrawingEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss // Dismisses the whole flow
    
    // Metadata passed from Step 1
    let book: String
    let chapter: Int
    let verse: Int
    let word: String
    let textColor: String
    
    // State for Drawing
    @State private var drawing = PKDrawing()
    @State private var canvasRect: CGRect = .zero
    
    // Alert state
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            Spacer()
            
            // The Composition Area
            ZStack {
                // Layer 1: White Background
                Color.white
                
                // Layer 2: Center Word
                Text(word)
                    .font(.system(size: 100, weight: .bold)) // Large base size
                    .lineLimit(1)
                    .minimumScaleFactor(0.1) // Shrink to fit
                    .foregroundColor(textColor == "white" ? .white : .black)
                    .padding(20) // Keep away from edges
                    .allowsHitTesting(false) // Let touches pass through to Canvas
                
                // Layer 3: Drawing Canvas
                CanvasView(drawing: $drawing)
            }
            .aspectRatio(1, contentMode: .fit) // Square Requirement
            .cornerRadius(12)
            .shadow(radius: 5)
            .padding()
            // Capture geometry for image generation size
            .background(
                GeometryReader { geo -> Color in
                    DispatchQueue.main.async {
                        self.canvasRect = geo.frame(in: .local)
                    }
                    return Color.clear
                }
            )
            
            Spacer()
        }
        .navigationTitle("\(book) \(chapter):\(verse)")
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveSketch()
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    func saveSketch() {
        // Generate Image
        let image = generateSnapshot()
        guard let imageData = image.pngData() else {
            errorMessage = "Failed to generate image."
            showingError = true
            return
        }
        
        let newSketch = SketchItem(context: viewContext)
        newSketch.id = UUID()
        newSketch.creationDate = Date()
        newSketch.bookName = book
        newSketch.chapter = Int16(chapter)
        newSketch.verse = Int16(verse)
        newSketch.centerWord = word
        newSketch.textColor = textColor
        newSketch.drawingData = drawing.dataRepresentation()
        newSketch.imageData = imageData
        
        // Find Canonical Order
        if let bookData = BibleDataStore.shared.books.first(where: { $0.name == book }) {
            newSketch.bookOrder = Int16(bookData.id)
        } else {
            newSketch.bookOrder = 0 // Fallback
        }
        
        do {
            try viewContext.save()
            // Dismiss the full creation flow (MetadataFormView was the root of this sheet)
            // Ideally we need to dismiss the parent sheet.
            // Since we are pushed, dismiss() pops us. We might need a binding to close the sheet from the root.
            // For now, I'll use a hack or assume the parent handles dismissal on save if I can't reach it.
            // Actually, if this View is in a NavigationStack presented as a sheet, `dismiss()` usually dismisses the sheet if it's the only thing? 
            // No, `dismiss()` on a pushed view pops it.
            // I need to use a binding passed down or NotificationCenter.
            // Let's use NotificationCenter for simplicity in this loose coupling, 
            // OR better: rely on the user tapping "Done" or handle this via a Root Environment Binding.
            
            // Re-eval check: MetadataFormView is start of sheet.
            // To dismiss the SHEet from here, we can search for a window root or use a specific binding.
            // I'll assume standard dismiss behavior might need help. 
            // Correct SwiftUI pattern: Pass a binding `isPresented` from the sheet root. 
            // I will fix MetadataFormView to accept a binding if needed, but for now let's try Notification.
            NotificationCenter.default.post(name: NSNotification.Name("DismissCreationSheet"), object: nil)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    @MainActor
    func generateSnapshot() -> UIImage {
        // Recreate the ZStack as a View for rendering
        let renderer = ImageRenderer(content:
            ZStack {
                Color.white
                Text(word)
                    .font(.system(size: 300, weight: .bold)) // Higher res for export
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .foregroundColor(textColor == "white" ? .white : .black)
                    .padding(60)
                
                // We need to render the PKDrawing too. 
                // ImageRenderer can handle standard SwiftUI views.
                // PKCanvasView isn't directly renderable by ImageRenderer easily without Image(uiImage:...)
                // Standard PKDrawing approach:
                Image(uiImage: drawing.image(from: CGRect(x: 0, y: 0, width: 1024, height: 1024), scale: 1.0))
            }
            .frame(width: 1024, height: 1024)
        )
        
        if let uiImage = renderer.uiImage {
            return uiImage
        }
        return UIImage()
    }
}
