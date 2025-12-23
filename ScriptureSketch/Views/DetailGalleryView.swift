import SwiftUI
import CoreData

struct DetailGalleryView: View {
    var items: [SketchItem]
    var title: String
    var contextMode: MainCatalogView.ViewMode // To know what caption to show

    var body: some View {
        Group {
            if contextMode == .word {
                // Word Mode: Master-Detail Album Layout
                WordDetailView(word: title)
            } else {
                // Scripture Mode: Grid Layout with FetchRequest
                ScriptureGridView(title: title, initialItems: items)
            }
        }
    }
}

// MARK: - Scripture Grid View (with FetchRequest)

/// Scripture Mode view that uses @FetchRequest for automatic updates
private struct ScriptureGridView: View {
    let title: String
    let initialItems: [SketchItem] // For fallback parsing

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest private var items: FetchedResults<SketchItem>

    // Grid columns - tight spacing for photo-album style
    let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]

    @State private var showingAddSketch = false
    @State private var refreshID = UUID()

    // Parse title to extract scripture components
    private var parsedScripture: (book: String, chapter: Int, verse: Int)? {
        // Title format: "Book Chapter:Verse"
        let components = title.split(separator: " ")
        guard components.count >= 2 else { return nil }

        let chapterVerse = String(components.last!)
        let cvParts = chapterVerse.split(separator: ":")
        guard cvParts.count == 2,
              let chapter = Int(cvParts[0]),
              let verse = Int(cvParts[1]) else { return nil }

        let book = components.dropLast().joined(separator: " ")
        return (book, chapter, verse)
    }

    init(title: String, initialItems: [SketchItem]) {
        self.title = title
        self.initialItems = initialItems

        // Try to parse scripture from title
        let components = title.split(separator: " ")
        var book = ""
        var chapter: Int16 = 0
        var verse: Int16 = 0

        if components.count >= 2 {
            let chapterVerse = String(components.last!)
            let cvParts = chapterVerse.split(separator: ":")
            if cvParts.count == 2,
               let ch = Int(cvParts[0]),
               let vs = Int(cvParts[1]) {
                chapter = Int16(ch)
                verse = Int16(vs)
                book = components.dropLast().joined(separator: " ")
            }
        }

        // Fallback: use first item's data if parsing failed
        if book.isEmpty, let firstItem = initialItems.first {
            book = firstItem.bookName ?? ""
            chapter = firstItem.chapter
            verse = firstItem.verse
        }

        // Create fetch request
        _items = FetchRequest<SketchItem>(
            sortDescriptors: [NSSortDescriptor(keyPath: \SketchItem.creationDate, ascending: true)],
            predicate: NSPredicate(
                format: "bookName == %@ AND chapter == %d AND verse == %d",
                book, chapter, verse
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header - Large title (verse reference)
                Text(title)
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Grid
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(items) { item in
                        NavigationLink {
                            // Pivot to Word Mode
                            WordDetailView(word: item.centerWord ?? "")
                        } label: {
                            SketchGridCell(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .id(refreshID)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSketch = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSketch) {
            if let scripture = parsedScripture {
                LockedScriptureFormWrapper(
                    isPresented: $showingAddSketch,
                    book: scripture.book,
                    chapter: scripture.chapter,
                    verse: scripture.verse
                )
            }
        }
        .onAppear {
            // Force refresh the fetch request when view appears
            refreshID = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DismissCreationSheet"))) { _ in
            showingAddSketch = false
        }
    }
}

// MARK: - Sketch Grid Cell

/// Square grid cell showing only the artwork image
private struct SketchGridCell: View {
    let item: SketchItem

    var body: some View {
        Group {
            // Use AdaptiveSketchImage to handle dual mode support
            AdaptiveSketchImage(item: item)
        }
        .clipped()
    }
}

// MARK: - Locked Scripture Form Wrapper

/// Wrapper to hold state and pass locked scripture to MetadataFormView
private struct LockedScriptureFormWrapper: View {
    @Binding var isPresented: Bool

    let lockedBook: String
    let lockedChapter: Int
    let lockedVerse: Int

    @State private var book: String
    @State private var chapter: Int
    @State private var verse: String
    @State private var word = ""
    @State private var textPosition = "below"

    init(isPresented: Binding<Bool>, book: String, chapter: Int, verse: Int) {
        self._isPresented = isPresented
        self.lockedBook = book
        self.lockedChapter = chapter
        self.lockedVerse = verse
        // Initialize state with locked values
        self._book = State(initialValue: book)
        self._chapter = State(initialValue: chapter)
        self._verse = State(initialValue: "\(verse)")
    }

    var body: some View {
        MetadataFormView(
            book: $book,
            chapter: $chapter,
            verse: $verse,
            word: $word,
            textPosition: $textPosition,
            lockedScripture: (lockedBook, lockedChapter, lockedVerse)
        )
    }
}

// MARK: - Preview Helpers

private struct PreviewHelper {
    static var genesisItems: [SketchItem] {
        let context = PersistenceController.preview.container.viewContext
        let request: NSFetchRequest<SketchItem> = SketchItem.fetchRequest()
        request.predicate = NSPredicate(format: "bookName == %@ AND chapter == %d AND verse == %d", "Genesis", 1, 1)
        return (try? context.fetch(request)) ?? []
    }

    static var faithItems: [SketchItem] {
        let context = PersistenceController.preview.container.viewContext
        let request: NSFetchRequest<SketchItem> = SketchItem.fetchRequest()
        request.predicate = NSPredicate(format: "centerWord == %@", "Faith")
        return (try? context.fetch(request)) ?? []
    }
}

#Preview("Scripture Mode - Carousel") {
    NavigationStack {
        DetailGalleryView(items: PreviewHelper.genesisItems, title: "Genesis 1:1", contextMode: .scripture)
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("Word Mode - Album") {
    NavigationStack {
        DetailGalleryView(items: PreviewHelper.faithItems, title: "Faith", contextMode: .word)
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
