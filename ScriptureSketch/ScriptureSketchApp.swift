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

    init() {
        // Perform one-time migration to group existing items by word
        MigrationService.shared.performMigrationIfNeeded(
            context: persistenceController.container.viewContext
        )
    }

    @State private var showingWelcome = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showingWelcome {
                    WelcomeView(isActive: $showingWelcome)
                } else {
                    MainCatalogView()
                        .transition(.opacity.animation(.easeIn(duration: 0.5)))
                }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
