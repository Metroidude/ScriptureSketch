import CoreData
import Foundation

/// Handles one-time data migrations for the app
class MigrationService {
    static let shared = MigrationService()
    private let migrationKey = "hasPerformedWordGroupMigration_v1"

    private init() {}

    /// Performs migration if needed. Call this at app launch.
    /// Groups existing SketchItems by centerWord and assigns shared drawing IDs.
    func performMigrationIfNeeded(context: NSManagedObjectContext) {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            return // Already migrated
        }

        let request: NSFetchRequest<SketchItem> = SketchItem.fetchRequest()
        request.predicate = NSPredicate(format: "sharedDrawingId == nil")

        guard let items = try? context.fetch(request), !items.isEmpty else {
            // No items need migration
            UserDefaults.standard.set(true, forKey: migrationKey)
            return
        }

        // Group by centerWord (case-insensitive, nil becomes "Unknown")
        let grouped = Dictionary(grouping: items) { item -> String in
            (item.centerWord ?? "Unknown").lowercased()
        }

        for (_, wordItems) in grouped {
            guard !wordItems.isEmpty else { continue }

            // Generate a shared ID for this word group
            let sharedId = UUID()

            // Sort by creation date to establish order (oldest first)
            let sorted = wordItems.sorted {
                ($0.creationDate ?? .distantFuture) < ($1.creationDate ?? .distantFuture)
            }

            // Assign the same sharedDrawingId to all items in this word group
            // IMPORTANT: We do NOT clear drawingData/imageData from any items.
            // All existing items keep their data. The "master" is determined at
            // runtime by the UI (oldest item with non-nil imageData).
            // This preserves all user artwork during migration.
            for item in sorted {
                item.sharedDrawingId = sharedId
            }
        }

        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: migrationKey)
        } catch {
            // Migration failed - don't set the flag so it retries next launch
            print("Migration failed: \(error.localizedDescription)")
        }
    }
}
