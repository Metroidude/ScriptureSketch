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
            // Do NOT create new UUID or date if updating, preserve history (unless requested otherwise)
        } else {
            sketch = SketchItem(context: viewContext)
            sketch.id = UUID()
            sketch.creationDate = Date()
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
                // FIX: Use explicit 1024x1024 rect instead of drawing.bounds to avoid cropping/offset issues
                Image(platformImage: drawing.image(from: CGRect(x: 0, y: 0, width: 1024, height: 1024), scale: 1.0))
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
