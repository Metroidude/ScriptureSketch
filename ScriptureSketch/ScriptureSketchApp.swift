import SwiftUI

@main
struct ScriptureSketchApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainCatalogView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
