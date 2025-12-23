# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build for iOS Simulator
xcodebuild -project ScriptureSketch.xcodeproj -scheme ScriptureSketch -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build for macOS
xcodebuild -project ScriptureSketch.xcodeproj -scheme ScriptureSketch -destination 'platform=macOS' build

# Run tests (when added)
xcodebuild -project ScriptureSketch.xcodeproj -scheme ScriptureSketch -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Open in Xcode: `open ScriptureSketch.xcodeproj`

## Architecture Overview

ScriptureSketch is a SwiftUI app for creating and cataloging Bible verse artwork. Users draw sketches around a "center word" from a scripture reference, then organize their collection by verse or word.

### Data Layer

- **SketchItem** (CoreData entity): Stores verse metadata (book, chapter, verse), a center word, drawing data (PencilKit), and rendered image. Uses `sharedDrawingId` to link multiple verses to the same artwork.
- **PersistenceController**: Programmatically defines the CoreData model (no .xcdatamodeld file) and uses `NSPersistentCloudKitContainer` for CloudKit sync.
- **BibleDataStore**: Static reference data for all 66 Bible books with chapter/verse counts for validation.
- **MigrationService**: One-time migration to add `sharedDrawingId` to legacy items, grouping by center word.

### View Hierarchy

```
ScriptureSketchApp
└── MainCatalogView (root, segmented by Scripture/Word mode)
    ├── DetailGalleryView
    │   ├── Scripture mode: TabView carousel of words for a verse
    │   └── Word mode: delegates to WordDetailView (album layout)
    └── MetadataFormView (sheet) → DrawingEditorView
```

### Key Patterns

- **Two View Modes**: `MainCatalogView.ViewMode` toggles between grouping by scripture reference or by center word.
- **Master/Linked Items**: When viewing by word, items share a `sharedDrawingId`. The "master" (oldest with imageData) provides the artwork; linked items only store metadata.
- **AddReferenceFormView**: Creates linked items that reference an existing drawing without duplicating image data.
- **Platform Abstraction**: `PlatformUtils.swift` defines `PlatformImage` and `ViewRepresentable` typealiases for iOS/macOS compatibility.
- **CanvasView**: Wraps `PKCanvasView` on iOS for drawing; falls back to read-only `NSImageView` on macOS.

### Supported Platforms

iOS 17.6+, macOS 14.6+, visionOS (deployment targets in project). Uses Swift 6 concurrency features (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`).
