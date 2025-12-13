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
    @NSManaged public var textColor: String? // "black" or "white"
    @NSManaged public var drawingData: Data?
    @NSManaged public var imageData: Data?
    @NSManaged public var bookOrder: Int16
}

extension SketchItem: Identifiable {
    // Computed property for easy access to a safe ID
    public var safeId: UUID {
        id ?? UUID()
    }
}
