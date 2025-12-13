import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // Add sample data for previews
        // Create a diverse set of sample items with duplicates to test grouping
        // Create a diverse set of sample items with duplicates to test grouping
        let samples: [(book: String, chapter: Int, verse: Int, word: String, color: String, order: Int)] = [
            ("Genesis", 1, 1, "Beginning", "black", 1), // Gen 1:1 #1
            ("Genesis", 1, 1, "Create", "white", 1),    // Gen 1:1 #2 (Same Verse, Diff Word)
            ("Genesis", 1, 1, "God", "black", 1),       // Gen 1:1 #3 (Same Verse, Diff Word)
            ("Psalms", 23, 1, "Shepherd", "black", 19),
            ("John", 3, 16, "Love", "white", 43), // Love #1
            ("1 John", 4, 8, "Love", "black", 62), // Love #2 (Grouping Test)
            ("Hebrews", 11, 1, "Faith", "black", 58), // Faith #1
            ("Romans", 10, 17, "Faith", "white", 45), // Faith #2 (Grouping Test)
            ("Matthew", 17, 20, "Faith", "black", 40), // Faith #3 (Grouping Test)
            ("Revelation", 22, 13, "Alpha", "white", 66),
            ("Exodus", 20, 3, "God", "black", 2),
            ("Isaiah", 40, 31, "Strength", "white", 23),
            ("Philippians", 4, 13, "Christ", "black", 50)
        ]
        
        for sample in samples {
            let newItem = SketchItem(context: viewContext)
            newItem.id = UUID()
            newItem.creationDate = Date() // All today, could vary this too if needed
            newItem.bookName = sample.book
            newItem.chapter = Int16(sample.chapter)
            newItem.verse = Int16(sample.verse)
            newItem.centerWord = sample.word
            newItem.textColor = sample.color
            newItem.bookOrder = Int16(sample.order)
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        // Create the Managed Object Model programmatically
        let model = NSManagedObjectModel()
        
        // Define the SketchItem Entity
        let sketchEntity = NSEntityDescription()
        sketchEntity.name = "SketchItem"
        sketchEntity.managedObjectClassName = "SketchItem"
        
        // Attributes
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        
        let dateAttr = NSAttributeDescription()
        dateAttr.name = "creationDate"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = false
        
        let bookNameAttr = NSAttributeDescription()
        bookNameAttr.name = "bookName"
        bookNameAttr.attributeType = .stringAttributeType
        bookNameAttr.isOptional = false
        
        let chapterAttr = NSAttributeDescription()
        chapterAttr.name = "chapter"
        chapterAttr.attributeType = .integer16AttributeType
        chapterAttr.isOptional = false
        
        let verseAttr = NSAttributeDescription()
        verseAttr.name = "verse"
        verseAttr.attributeType = .integer16AttributeType
        verseAttr.isOptional = false
        
        // Index for sorting books correctly
        let bookOrderAttr = NSAttributeDescription()
        bookOrderAttr.name = "bookOrder"
        bookOrderAttr.attributeType = .integer16AttributeType
        bookOrderAttr.isOptional = false
        
        let centerWordAttr = NSAttributeDescription()
        centerWordAttr.name = "centerWord"
        centerWordAttr.attributeType = .stringAttributeType
        centerWordAttr.isOptional = false
        
        let textColorAttr = NSAttributeDescription()
        textColorAttr.name = "textColor"
        textColorAttr.attributeType = .stringAttributeType
        textColorAttr.isOptional = false
        
        let drawingDataAttr = NSAttributeDescription()
        drawingDataAttr.name = "drawingData"
        drawingDataAttr.attributeType = .binaryDataAttributeType
        drawingDataAttr.isOptional = true
        
        let imageDataAttr = NSAttributeDescription()
        imageDataAttr.name = "imageData"
        imageDataAttr.attributeType = .binaryDataAttributeType
        imageDataAttr.isOptional = true
        
        sketchEntity.properties = [
            idAttr, dateAttr, bookNameAttr, chapterAttr, verseAttr, bookOrderAttr,
            centerWordAttr, textColorAttr, drawingDataAttr, imageDataAttr
        ]
        
        model.entities = [sketchEntity]
        
        // Initialize Container with the programmatic model
        container = NSPersistentCloudKitContainer(name: "ScriptureSketch", managedObjectModel: model)
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
