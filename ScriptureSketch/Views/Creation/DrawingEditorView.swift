import SwiftUI
import PencilKit
import CoreData

struct DrawingEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss // Dismisses the whole flow
    
    @Environment(\.undoManager) var undoManager

    // Metadata passed from Step 1
    let book: String
    let chapter: Int
    let verse: Int
    let word: String
    let textColor: String
    
    // Optional existing item for Editing Mode
    var itemToEdit: SketchItem?
    
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

                // Layer ordering based on textColor (now represents position)
                if textColor == "top" {
                    // Drawing below, text on top
                    CanvasView(drawing: $drawing)

                    Text(word)
                        .font(.system(size: 100, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.1)
                        .foregroundStyle(
                            .black.shadow(.drop(color: .white, radius: 2))
                        )
                        .padding(20)
                        .allowsHitTesting(false)
                } else {
                    // Text below, drawing on top (default)
                    Text(word)
                        .font(.system(size: 100, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.1)
                        .foregroundStyle(
                            .black.shadow(.drop(color: .white, radius: 2))
                        )
                        .padding(20)
                        .allowsHitTesting(false)

                    CanvasView(drawing: $drawing)
                }
            }
            .aspectRatio(1, contentMode: .fit) // Square Requirement
            .cornerRadius(12)
            .shadow(radius: 5)
            .padding()
            // Capture geometry for image generation size
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        self.canvasRect = geo.frame(in: .local)
                        // If editing, load the drawing data
                        if let item = itemToEdit, let data = item.drawingData {
                             try? self.drawing = PKDrawing(data: data)
                        }
                    }
                }
            )
            
            Spacer()
        }
        .navigationTitle("\(book) \(chapter):\(verse)")
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(itemToEdit != nil ? "Update" : "Save") {
                    saveSketch()
                }
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {
                    undoManager?.undo()
                }) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!(undoManager?.canUndo ?? false))
                
                Button(action: {
                    undoManager?.redo()
                }) {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(!(undoManager?.canRedo ?? false))
                
                Spacer()
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
        
        let sketch: SketchItem
        if let existingItem = itemToEdit {
            sketch = existingItem
            // Do NOT create new UUID or date if updating, preserve history
            // Preserve existing sharedDrawingId (linked items share this)
        } else {
            sketch = SketchItem(context: viewContext)
            sketch.id = UUID()
            sketch.creationDate = Date()
            // New items get their own sharedDrawingId
            // (Other verses can link to this later via AddReferenceFormView)
            sketch.sharedDrawingId = UUID()
        }
        
        // Update fields
        sketch.bookName = book
        sketch.chapter = Int16(chapter)
        sketch.verse = Int16(verse)
        sketch.centerWord = word
        sketch.textColor = textColor
        sketch.drawingData = drawing.dataRepresentation()
        sketch.imageData = imageData
        
        // Find Canonical Order
        if let bookData = BibleDataStore.shared.books.first(where: { $0.name == book }) {
            sketch.bookOrder = Int16(bookData.id)
        } else {
            sketch.bookOrder = 0 // Fallback
        }
        
        do {
            try viewContext.save()
            // Dismiss flow
            NotificationCenter.default.post(name: NSNotification.Name("DismissCreationSheet"), object: nil)
            // If pushed (Edit Mode), we also need to pop back.
            if itemToEdit != nil {
                dismiss() 
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    @MainActor
    func generateSnapshot() -> PlatformImage {
        // Capture the canvas size and scale drawing to fill 1024x1024 output
        let targetSize: CGFloat = 1024.0
        let sourceRect = (canvasRect == .zero) ? drawing.bounds : canvasRect
        let scale = (sourceRect.width > 0) ? (targetSize / sourceRect.width) : 1.0
        
        // Pre-render the drawing image
        let drawingImage = drawing.image(from: sourceRect, scale: scale)
        
        // Recreate the ZStack as a View for rendering with same layer order as editor
        let renderer = ImageRenderer(content:
            ZStack {
                // Background removed for transparency

                if textColor == "top" {
                    // Drawing below, text on top
                    Image(platformImage: drawingImage)
                        .resizable()
                        .frame(width: 1024, height: 1024)

                    Text(word)
                        .font(.system(size: 300, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.1)
                        .foregroundStyle(
                            .black.shadow(.drop(color: .white, radius: 4))
                        )
                        .padding(60)
                } else {
                    // Text below, drawing on top (default)
                    Text(word)
                        .font(.system(size: 300, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.1)
                        .foregroundStyle(
                            .black.shadow(.drop(color: .white, radius: 4))
                        )
                        .padding(60)

                    Image(platformImage: drawingImage)
                        .resizable()
                        .frame(width: 1024, height: 1024)
                }
            }
            .frame(width: 1024, height: 1024)
        )
        
#if os(macOS)
        if let nsImage = renderer.nsImage {
            return nsImage
        }
#else
        if let uiImage = renderer.uiImage {
            return uiImage
        }
#endif
        return PlatformImage()
    }
}

#Preview {
    NavigationStack {
        DrawingEditorView(
            book: "John",
            chapter: 3,
            verse: 16,
            word: "LOVE",
            textColor: "black"
        )
    }
}
