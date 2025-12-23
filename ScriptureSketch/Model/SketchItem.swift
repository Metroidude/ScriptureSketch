import Foundation
import CoreData

@objc(SketchItem)
public class SketchItem: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var creationDate: Date?
    @NSManaged public var bookName: String?
    @NSManaged public var chapter: Int16
    @NSManaged public var verse: Int16
    @NSManaged public var centerWord: String?
    @NSManaged public var textColor: String? // "below" (text under drawing) or "top" (text over drawing)
    @NSManaged public var drawingData: Data?
    @NSManaged public var imageData: Data?
    @NSManaged public var bookOrder: Int16
    @NSManaged public var sharedDrawingId: UUID?
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SketchItem> {
        return NSFetchRequest<SketchItem>(entityName: "SketchItem")
    }
}

extension SketchItem: Identifiable {
    // Computed property for easy access to a safe ID
    public var safeId: UUID {
        id ?? UUID()
    }

    /// Returns imageData from this item, or from the master item if this is a linked reference.
    /// Linked items have no imageData but share a sharedDrawingId with the master.
    public var effectiveImageData: Data? {
        // If this item has its own image data, use it
        if let data = imageData {
            return data
        }

        // If this is a linked item, find the master with the same sharedDrawingId
        guard let drawingId = sharedDrawingId,
              let context = managedObjectContext else {
            return nil
        }

        let request: NSFetchRequest<SketchItem> = SketchItem.fetchRequest()
        request.predicate = NSPredicate(
            format: "sharedDrawingId == %@ AND imageData != nil",
            drawingId as CVarArg
        )
        request.fetchLimit = 1

        if let master = try? context.fetch(request).first {
            return master.imageData
        }

        return nil
    }
}
