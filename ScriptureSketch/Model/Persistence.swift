import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

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
