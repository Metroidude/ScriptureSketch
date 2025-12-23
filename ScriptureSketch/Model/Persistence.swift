import CoreData
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Sample data that simulates realistic user behavior:
        // - First entry for a word is the "master" with drawing/image data
        // - Subsequent entries for same word are "linked" (nil image data)
        // - "Faith" has 15+ references to test scrolling
        // - Genesis 1:1 is referenced by multiple words

        // Structure: (book, chapter, verse, word, color, order, isMaster)
        // isMaster = true means this is the first/original drawing for this word
        let samples: [(book: String, chapter: Int, verse: Int, word: String, color: String, order: Int, isMaster: Bool)] = [
            // === FAITH - Many references (15+) to test scrolling ===
            // Master entry (user drew this first)
            ("Hebrews", 11, 1, "Faith", "black", 58, true),
            // Linked entries (user added these verses later)
            ("Romans", 10, 17, "Faith", "black", 45, false),
            ("Matthew", 17, 20, "Faith", "black", 40, false),
            ("Galatians", 2, 20, "Faith", "black", 48, false),
            ("Ephesians", 2, 8, "Faith", "black", 49, false),
            ("James", 2, 17, "Faith", "black", 59, false),
            ("1 Peter", 1, 7, "Faith", "black", 60, false),
            ("Mark", 11, 22, "Faith", "black", 41, false),
            ("Luke", 17, 6, "Faith", "black", 42, false),
            ("Romans", 1, 17, "Faith", "black", 45, false),
            ("2 Corinthians", 5, 7, "Faith", "black", 47, false),
            ("Habakkuk", 2, 4, "Faith", "black", 35, false),
            ("Hebrews", 11, 6, "Faith", "black", 58, false),
            ("Hebrews", 12, 2, "Faith", "black", 58, false),
            ("1 Timothy", 6, 12, "Faith", "black", 54, false),

            // === GENESIS 1:1 - Referenced by multiple words ===
            ("Genesis", 1, 1, "Beginning", "black", 1, true),
            ("Genesis", 1, 1, "Create", "white", 1, true),
            ("Genesis", 1, 1, "God", "black", 1, true),
            ("Genesis", 1, 1, "Heaven", "white", 1, true),
            ("Genesis", 1, 1, "Earth", "black", 1, true),

            // === OTHER WORDS - Normal usage patterns ===
            // Love - master + a few links
            ("John", 3, 16, "Love", "white", 43, true),
            ("1 John", 4, 8, "Love", "white", 62, false),
            ("Romans", 8, 38, "Love", "white", 45, false),
            ("1 Corinthians", 13, 4, "Love", "white", 46, false),

            // God - master + links
            ("Exodus", 20, 3, "God", "black", 2, false),  // Links to Genesis 1:1 God
            ("Psalm", 46, 10, "God", "black", 19, false),
            ("Isaiah", 40, 28, "God", "black", 23, false),

            // Single entries (user only drew once)
            ("Psalms", 23, 1, "Shepherd", "black", 19, true),
            ("Revelation", 22, 13, "Alpha", "white", 66, true),
            ("Isaiah", 40, 31, "Strength", "white", 23, true),
            ("Philippians", 4, 13, "Christ", "black", 50, true),

            // Hope - master + a few links
            ("Romans", 15, 13, "Hope", "black", 45, true),
            ("Hebrews", 6, 19, "Hope", "black", 58, false),
            ("1 Peter", 1, 3, "Hope", "black", 60, false),

            // Grace - master + links
            ("Ephesians", 2, 8, "Grace", "white", 49, true),
            ("2 Corinthians", 12, 9, "Grace", "white", 47, false),
            ("Romans", 5, 8, "Grace", "white", 45, false),
        ]

        // Pre-generate sharedDrawingIds for each unique word
        var wordToSharedId: [String: UUID] = [:]
        for sample in samples {
            if wordToSharedId[sample.word] == nil {
                wordToSharedId[sample.word] = UUID()
            }
        }

        // Use incrementing dates so "master" entries are oldest
        var dateOffset: TimeInterval = 0

        for sample in samples {
            let newItem = SketchItem(context: viewContext)
            newItem.id = UUID()
            // Masters get older dates, linked entries get newer dates
            newItem.creationDate = Date().addingTimeInterval(-86400 * 30 + dateOffset)
            dateOffset += 3600 // Each entry is 1 hour newer
            newItem.bookName = sample.book
            newItem.chapter = Int16(sample.chapter)
            newItem.verse = Int16(sample.verse)
            newItem.centerWord = sample.word
            newItem.textColor = sample.color
            newItem.bookOrder = Int16(sample.order)
            newItem.sharedDrawingId = wordToSharedId[sample.word]

            // Only master entries get image data (simulates real user flow)
            if sample.isMaster {
                newItem.imageData = generatePreviewImage(word: sample.word, textColor: sample.color)
            }
            // Linked entries have nil imageData - they reference the master's drawing
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    /// Generates a simple preview image with the word centered
    private static func generatePreviewImage(word: String, textColor: String) -> Data? {
        #if os(iOS)
        let size = CGSize(width: 256, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // Background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw word
            let textColorUI: UIColor = textColor == "white" ? .lightGray : .black
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 40),
                .foregroundColor: textColorUI
            ]
            let textSize = word.size(withAttributes: attributes)
            let point = CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            )
            word.draw(at: point, withAttributes: attributes)
            
            // Draw some decorative lines to simulate a sketch
            context.cgContext.setStrokeColor(UIColor.blue.withAlphaComponent(0.5).cgColor)
            context.cgContext.setLineWidth(3)
            context.cgContext.move(to: CGPoint(x: 30, y: 30))
            context.cgContext.addLine(to: CGPoint(x: 80, y: 80))
            context.cgContext.move(to: CGPoint(x: size.width - 30, y: size.height - 30))
            context.cgContext.addLine(to: CGPoint(x: size.width - 80, y: size.height - 80))
            context.cgContext.strokePath()
        }
        return image.pngData()
        #else
        // macOS fallback - create a simple colored image
        let size = NSSize(width: 256, height: 256)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        let textColorNS: NSColor = textColor == "white" ? .lightGray : .black
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 40),
            .foregroundColor: textColorNS
        ]
        let textSize = word.size(withAttributes: attributes)
        let point = NSPoint(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2
        )
        word.draw(at: point, withAttributes: attributes)
        image.unlockFocus()
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
        #endif
    }

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        // Create the Managed Object Model programmatically
        let model = NSManagedObjectModel()
        
        // Define the SketchItem Entity
        let sketchEntity = NSEntityDescription()
        sketchEntity.name = "SketchItem"
        sketchEntity.managedObjectClassName = "SketchItem"
        
        // Attributes (CloudKit requires default values for non-optional attributes)
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        idAttr.defaultValue = UUID()

        let dateAttr = NSAttributeDescription()
        dateAttr.name = "creationDate"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = false
        dateAttr.defaultValue = Date()

        let bookNameAttr = NSAttributeDescription()
        bookNameAttr.name = "bookName"
        bookNameAttr.attributeType = .stringAttributeType
        bookNameAttr.isOptional = false
        bookNameAttr.defaultValue = ""

        let chapterAttr = NSAttributeDescription()
        chapterAttr.name = "chapter"
        chapterAttr.attributeType = .integer16AttributeType
        chapterAttr.isOptional = false
        chapterAttr.defaultValue = Int16(1)

        let verseAttr = NSAttributeDescription()
        verseAttr.name = "verse"
        verseAttr.attributeType = .integer16AttributeType
        verseAttr.isOptional = false
        verseAttr.defaultValue = Int16(1)

        // Index for sorting books correctly
        let bookOrderAttr = NSAttributeDescription()
        bookOrderAttr.name = "bookOrder"
        bookOrderAttr.attributeType = .integer16AttributeType
        bookOrderAttr.isOptional = false
        bookOrderAttr.defaultValue = Int16(0)

        let centerWordAttr = NSAttributeDescription()
        centerWordAttr.name = "centerWord"
        centerWordAttr.attributeType = .stringAttributeType
        centerWordAttr.isOptional = false
        centerWordAttr.defaultValue = ""

        let textColorAttr = NSAttributeDescription()
        textColorAttr.name = "textColor"
        textColorAttr.attributeType = .stringAttributeType
        textColorAttr.isOptional = false
        textColorAttr.defaultValue = "below"  // "below" = text under drawing, "top" = text over drawing
        
        let drawingDataAttr = NSAttributeDescription()
        drawingDataAttr.name = "drawingData"
        drawingDataAttr.attributeType = .binaryDataAttributeType
        drawingDataAttr.isOptional = true
        drawingDataAttr.allowsExternalBinaryDataStorage = true
        
        let imageDataAttr = NSAttributeDescription()
        imageDataAttr.name = "imageData"
        imageDataAttr.attributeType = .binaryDataAttributeType
        imageDataAttr.isOptional = true
        imageDataAttr.allowsExternalBinaryDataStorage = true

        let sharedDrawingIdAttr = NSAttributeDescription()
        sharedDrawingIdAttr.name = "sharedDrawingId"
        sharedDrawingIdAttr.attributeType = .UUIDAttributeType
        sharedDrawingIdAttr.isOptional = true

        sketchEntity.properties = [
            idAttr, dateAttr, bookNameAttr, chapterAttr, verseAttr, bookOrderAttr,
            centerWordAttr, textColorAttr, drawingDataAttr, imageDataAttr, sharedDrawingIdAttr
        ]
        
        model.entities = [sketchEntity]
        
        // Initialize Container with the programmatic model
        container = NSPersistentCloudKitContainer(name: "ScriptureSketch", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure CloudKit container
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("No persistent store description found")
            }
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.homeworkmuffin.scripturesketch"
            )
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
