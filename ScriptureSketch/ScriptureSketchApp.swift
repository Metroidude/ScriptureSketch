//
//  ScriptureSketchApp.swift
//  ScriptureSketch
//
//  Created by Joel Kendall on 12/12/25.
//

import SwiftUI
import CoreData

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
