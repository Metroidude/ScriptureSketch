//
//  ScriptureSketchAppApp.swift
//  ScriptureSketchApp
//
//  Created by Joel Kendall on 12/12/25.
//

import SwiftUI
import CoreData

@main
struct ScriptureSketchAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
