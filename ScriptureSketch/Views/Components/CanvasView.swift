import SwiftUI
import PencilKit
#if os(macOS)
import AppKit
#endif

// Ensure ViewRepresentable conforms correctly on both platforms
struct CanvasView: ViewRepresentable {
    @Binding var drawing: PKDrawing
    
    // PKToolPicker is managed by Coordinator on iOS
    
#if os(macOS)
    // macOS Implementation: Read-Only via NSImageView
    // Note: PKCanvasView is not available in native AppKit (requires Catalyst).
    // We render the drawing as an image for display.
    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.contentTintColor = .black
        return imageView
    }
    
    func updateNSView(_ nsView: NSImageView, context: Context) {
        // Render the PKDrawing to an NSImage
        // We use a reasonably large rect to capture the drawing.
        // In a real app, matching the view bounds is better, but here we use the binding.
        let image = drawing.image(from: drawing.bounds, scale: 1.0)
        nsView.image = image
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: CanvasView
        init(_ parent: CanvasView) {
            self.parent = parent
        }
    }
    
#else
    // iOS Implementation
    func makeUIView(context: Context) -> PKCanvasView {
        print("DEBUG: makeUIView called for CanvasView")
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        
        canvas.delegate = context.coordinator
        
        // Use the coordinator's tool picker
        context.coordinator.toolPicker.setVisible(true, forFirstResponder: canvas)
        context.coordinator.toolPicker.addObserver(canvas)
        canvas.becomeFirstResponder()
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasView
        let toolPicker = PKToolPicker()
        
        init(_ parent: CanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
#endif
}

#Preview {
    CanvasView(drawing: .constant(PKDrawing()))
}
