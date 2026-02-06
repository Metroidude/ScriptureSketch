import SwiftUI
import SpriteKit
import CoreData

#if os(macOS)
import AppKit
typealias PlatformView = NSView
#else
import UIKit
typealias PlatformView = UIView
#endif

struct BackgroundAnimationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @Environment(\.colorScheme) var colorScheme
    
    // Fetch recent items with images to use
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.creationDate, order: .reverse)],
        // Modified predicate to search for EITHER imageData OR imageDataDark being present
        // Since we can't easily query "imageData != nil OR imageDataDark != nil" in one go for efficient CloudKit sync sometimes,
        // we'll stick to basic fetch and filter in memory if needed, or assume old items have imageData.
        // For now, let's keep the predicate simple or update it if we want to catch "Dark Mode Only" items (unlikely).
        predicate: NSPredicate(format: "imageData != nil OR imageDataDark != nil"),
        animation: .default)
    private var items: FetchedResults<SketchItem>
    
    var body: some View {
        // Converting data to images. 
        // We limit to 20 to avoid memory pressure if images are large.
        // We resolve the correct image variant (Light vs Dark) based on current environment.
        let images: [PlatformImage] = items.prefix(20).compactMap { item in
            if colorScheme == .dark, let darkData = item.effectiveImageDataDark {
                return PlatformImage(data: darkData)
            } else if let lightData = item.effectiveImageData {
                return PlatformImage(data: lightData)
            }
            return nil
        }
        
        SpriteKitContainer(userImages: images)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

struct SpriteKitContainer: ViewRepresentable {
    let userImages: [PlatformImage]
    
    func makeScene() -> ActingFallingImagesScene {
        let scene = ActingFallingImagesScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }
    
    func updateScene(_ scene: ActingFallingImagesScene) {
        // Always update images so that content changes (Light <-> Dark) are reflected
        // even if the count remains the same.
        scene.userImages = userImages
    }

    #if os(macOS)
    func makeNSView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.backgroundColor = .clear
        view.ignoresSiblingOrder = true
        view.presentScene(makeScene())
        return view
    }
    
    func updateNSView(_ nsView: SKView, context: Context) {
        if let scene = nsView.scene as? ActingFallingImagesScene {
            updateScene(scene)
        }
    }
    #else
    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.backgroundColor = .clear
        view.ignoresSiblingOrder = true
        view.presentScene(makeScene())
        return view
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        if let scene = uiView.scene as? ActingFallingImagesScene {
            updateScene(scene)
        }
    }
    #endif
}

// MARK: - Falling Images SpriteKit Scene

final class ActingFallingImagesScene: SKScene {
    
    var userImages: [PlatformImage] = [] {
        didSet {
            // Reload textures when images change
            loadTextures()
        }
    }

    private var textures: [SKTexture] = []
    private var didStart = false  

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        loadTextures()
        startIfPossible()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        startIfPossible()
    }
    
    private func loadTextures() {
        var newTextures: [SKTexture] = []
        
        // 1. User Images
        if !userImages.isEmpty {
             newTextures = userImages.map { SKTexture(image: $0) }
        } else {
            // 2. Default Images from Bundle (FallingImages folder)
            // We lazily look for images named "Falling1", "Falling2"... or in folder
            newTextures = loadDefaultTextures()
        }
        
        self.textures = newTextures
    }
    
    private func loadDefaultTextures() -> [SKTexture] {
        var foundTextures: [SKTexture] = []
        let bundle = Bundle.main
        
        // Strategy 1: "Folder Reference" (Blue Folder)
        // We look for the folder URL and iterate its contents manually.
        if let folderURL = bundle.url(forResource: "FallingImages", withExtension: nil) {
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
                for url in fileURLs {
                    let ext = url.pathExtension.lowercased()
                    if ["png", "jpg", "jpeg", "gif"].contains(ext) {
                        // Load image
                        #if os(macOS)
                        if let image = NSImage(contentsOf: url) {
                            foundTextures.append(SKTexture(image: image))
                        }
                        #else
                        if let image = UIImage(contentsOfFile: url.path) {
                            foundTextures.append(SKTexture(image: image))
                        }
                        #endif
                    }
                }
            } catch {
                print("Error listing FallingImages folder: \(error)")
            }
        }
        
        // Strategy 2: Targeted search inside "FallingImages" folder
        if foundTextures.isEmpty {
            for i in 1...10 {
                let name = "Falling\(i)"
                var image: PlatformImage?
                
                // Try specific subdirectory search
                if let path = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "FallingImages") {
                    #if os(macOS)
                    image = NSImage(contentsOfFile: path)
                    #else
                    image = UIImage(contentsOfFile: path)
                    #endif
                }
                
                // Backup: Try root/Assets
                if image == nil {
                     #if os(macOS)
                     image = NSImage(named: name)
                     #else
                     image = UIImage(named: name)
                     #endif
                }
                
                if let validImage = image {
                    foundTextures.append(SKTexture(image: validImage))
                }
            }
        }
        
        // Strategy 3: Ultimate Fallback (SF Symbols)
        // If we still found nothing, usage system images so the user sees *something*
        if foundTextures.isEmpty {
            print("FallingImages: No local files found. Using system placeholders.")
            let systems = ["star", "cloud", "camera.macro", "drop", "leaf"]
            for name in systems {
                #if os(macOS)
                if let image = NSImage(systemSymbolName: name, accessibilityDescription: nil) {
                     foundTextures.append(SKTexture(image: image))
                }
                #else
                if let image = UIImage(systemName: name) {
                     foundTextures.append(SKTexture(image: image))
                }
                #endif
            }
        } else {
             print("FallingImages: Found \(foundTextures.count) images.")
        }
        
        return foundTextures
    }

    private func startIfPossible() {
        guard !didStart, size.width > 10, size.height > 10 else { return }
        didStart = true
        spawnLoop()
    }

    private var isPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }

    // Spawn LESS often
    private func spawnLoop() {
        let spawn = SKAction.run { [weak self] in self?.spawnOne() }
        // More frequent on iPad (0.4) vs iPhone (0.9)
        let waitDuration = isPad ? 0.4 : 0.9 
        let wait = SKAction.wait(forDuration: waitDuration)
        run(.repeatForever(.sequence([spawn, wait])))
    }

    private func spawnOne() {
        guard !textures.isEmpty else { return }
        guard children.count < 50 else { return }

        let node = SKSpriteNode(texture: textures.randomElement()!)
        node.alpha = 0.95

        // Larger on iPad
        let minScale: CGFloat = isPad ? 0.30 : 0.18
        let maxScale: CGFloat = isPad ? 0.50 : 0.30
        let scale = CGFloat.random(in: minScale...maxScale)
        node.setScale(scale)

        // Start just ABOVE the top
        let x = CGFloat.random(in: 0...size.width)
        node.position = CGPoint(x: x, y: size.height + 80)

        // Random rotation
        node.zRotation = CGFloat.random(in: -0.2...0.2)
        addChild(node)

        // Time to fall
        let duration: TimeInterval = 8.0

        let moveDown = SKAction.moveTo(y: -600, duration: duration)
        
        // Optional gentle rotation
        let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -1.0...1.0), duration: duration)
        
        // Fade only near the end
        let fadeNearEnd = SKAction.sequence([
            .wait(forDuration: duration * 0.75),
            .fadeOut(withDuration: duration * 0.25)
        ])
        
        let fall = SKAction.group([moveDown, rotate, fadeNearEnd])
        node.run(.sequence([fall, .removeFromParent()]))
    }
}
