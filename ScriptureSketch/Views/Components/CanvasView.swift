import SwiftUI
import Combine
import PencilKit
#if os(macOS)
import AppKit
#endif

// Helper to expose internal state like UndoManager and observe its changes
class CanvasState: ObservableObject {
    @Published var undoManager: UndoManager? {
        didSet {
            setupObservers()
        }
    }
    
    private var observers: [AnyCancellable] = []
    
    private func setupObservers() {
        observers.removeAll()
        
        guard let manager = undoManager else { return }
        
        // Listen for UndoManager changes to refresh UI (enable/disable buttons)
        let center = NotificationCenter.default
        let names = [
            NSNotification.Name.NSUndoManagerDidUndoChange,
            NSNotification.Name.NSUndoManagerDidRedoChange,
            NSNotification.Name.NSUndoManagerDidOpenUndoGroup,
            NSNotification.Name.NSUndoManagerDidCloseUndoGroup,
            NSNotification.Name.NSUndoManagerCheckpoint // Important for grouping
        ]
        
        for name in names {
            center.publisher(for: name, object: manager)
                .sink { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.objectWillChange.send()
                    }
                }
                .store(in: &observers)
        }
        print("DEBUG: CanvasState setupObservers complete for manager: \(manager)")
    }
}

// Ensure ViewRepresentable conforms correctly on both platforms
struct CanvasView: ViewRepresentable {
    @Binding var drawing: PKDrawing
    @ObservedObject var canvasState: CanvasState
    
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
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        
        // Expose Native UndoManager
        // Dispatch async to ensure it's captured after init if needed, though usually immediate is fine.
        DispatchQueue.main.async {
            context.coordinator.parent.canvasState.undoManager = canvas.undoManager
        }
        
        canvas.delegate = context.coordinator
        
        // Use the coordinator's tool picker
        context.coordinator.toolPicker.setVisible(true, forFirstResponder: canvas)
        context.coordinator.toolPicker.addObserver(canvas)
        canvas.becomeFirstResponder()
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Vital: Update coordinator's parent to the latest struct so the binding reference is current
        context.coordinator.parent = self
        
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
            print("DEBUG: canvasViewDrawingDidChange. Strokes: \(canvasView.drawing.strokes.count)")
            // Avoid cycle: Only update if different
            if parent.drawing != canvasView.drawing {
                 parent.drawing = canvasView.drawing
            }
        }
    }
#endif
}

#Preview("Sample Drawing") {
    // Render a sample PKDrawing as an Image (PKCanvasView doesn't preview reliably)
    let sampleDrawing: PKDrawing = {
        var drawing = PKDrawing()
        let ink = PKInk(.pen, color: .blue)
        let points: [CGPoint] = [
            CGPoint(x: 50, y: 50),
            CGPoint(x: 150, y: 150),
            CGPoint(x: 250, y: 100),
            CGPoint(x: 350, y: 200)
        ]
        var strokePoints: [PKStrokePoint] = []
        for (index, point) in points.enumerated() {
            strokePoints.append(PKStrokePoint(
                location: point,
                timeOffset: TimeInterval(index) * 0.1,
                size: CGSize(width: 5, height: 5),
                opacity: 1.0,
                force: 1.0,
                azimuth: 0,
                altitude: .pi / 2
            ))
        }
        let path = PKStrokePath(controlPoints: strokePoints, creationDate: Date())
        drawing.strokes.append(PKStroke(ink: ink, path: path))
        return drawing
    }()
    
    let drawingImage = sampleDrawing.image(from: CGRect(x: 0, y: 0, width: 400, height: 400), scale: 2.0)
    
    Image(platformImage: drawingImage)
        .resizable()
        .frame(width: 400, height: 400)
        .background(Color.white)
        .cornerRadius(12)
}

#Preview("Empty Canvas") {
    CanvasView(drawing: .constant(PKDrawing()), canvasState: CanvasState())
        .frame(width: 400, height: 400)
        .background(Color.white)
}
