import SwiftUI
import CoreData

/// Master-Detail album view for Word Mode
/// Displays a large "billboard" image at top with the word title,
/// followed by a list of linked scripture references.
struct WordDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let word: String
    @Environment(\.dismiss) private var dismiss 

    // Use @FetchRequest to observe Core Data changes and auto-refresh
    @FetchRequest private var items: FetchedResults<SketchItem>

    @State private var showingAddReference = false
    @State private var itemToDelete: SketchItem?
    @State private var showDeleteConfirmation = false
    @State private var isEditingDrawing = false

    init(word: String, items: [SketchItem] = []) {
        self.word = word
        // Create a fetch request filtered by centerWord
        _items = FetchRequest<SketchItem>(
            sortDescriptors: [NSSortDescriptor(keyPath: \SketchItem.creationDate, ascending: true)],
            predicate: NSPredicate(format: "centerWord ==[c] %@", word)
        )
    }

    // MARK: - Computed Properties

    /// The "master" item: oldest item that has actual image data.
    /// Falls back to oldest item if none have image data.
    var masterItem: SketchItem? {
        // First, try to find an item with image data (sorted by creation date)
        let withImage = items
            .filter { $0.imageData != nil }

        if let master = withImage.first {
            return master
        }

        // Fallback: return oldest item even if it has no image data
        return items.first
    }

    /// The image to display in the billboard, from the master item
    var masterImage: PlatformImage? {
        guard let imageData = masterItem?.imageData else { return nil }
        return PlatformImage.from(data: imageData)
    }

    /// All references sorted by canonical Bible order
    var sortedReferences: [SketchItem] {
        Array(items).sorted { item1, item2 in
            if item1.bookOrder != item2.bookOrder {
                return item1.bookOrder < item2.bookOrder
            }
            if item1.chapter != item2.chapter {
                return item1.chapter < item2.chapter
            }
            return item1.verse < item2.verse
        }
    }

    // MARK: - Body

    var body: some View {
        List {
            // FIX: Place billboardSection here as a regular item.
            // By moving it out of the Section(header:...), it will scroll naturally with the list.
            billboardSection
                .listRowSeparator(.hidden) // Optional: hides the line below the image
                .listRowInsets(EdgeInsets()) // Optional: removes default side padding if you want edge-to-edge

            // Content Section
            Section {
                // Add Reference Button
                Button {
                    showingAddReference = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        Text("Link another Verse")
                            .foregroundColor(.blue)
                    }
                }

                // Reference Rows with swipe-to-delete
                ForEach(sortedReferences) { item in
                    ReferenceRow(item: item, masterItem: masterItem)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                handleDelete(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(word)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isEditingDrawing = true
                } label: {
                    Image(systemName: "pencil")
                }
                .disabled(masterItem == nil)
            }
        }
        .sheet(isPresented: $showingAddReference) {
            AddReferenceFormView(
                word: word,
                sharedDrawingId: masterItem?.sharedDrawingId
            )
        }
        .alert("Delete Drawing?", isPresented: $showDeleteConfirmation) {
            Button("Delete Artwork", role: .destructive) {
                confirmDelete()
            }
            Button("Cancel", role: .cancel) {
                itemToDelete = nil
            }
        } message: {
            Text("This is the last verse using this drawing. Deleting it will permanently remove the artwork.")
        }
        .navigationDestination(isPresented: $isEditingDrawing) {
            if let master = masterItem,
               let book = master.bookName,
               let masterWord = master.centerWord,
               let color = master.textColor {
                DrawingEditorView(
                    book: book,
                    chapter: Int(master.chapter),
                    verse: Int(master.verse),
                    word: masterWord,
                    textColor: color,
                    itemToEdit: master
                )
            }
        }
    }

    // MARK: - Billboard Section

    @ViewBuilder
    var billboardSection: some View {
        VStack(spacing: 12) {
            if let image = masterImage {
                Image(platformImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            } else {
                // Placeholder when no image exists
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(12)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No artwork yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
        .padding(.vertical)
        // Add horizontal padding here if you removed ListRowInsets above but still want padding around the image
        .padding(.horizontal)
    }

    // MARK: - Deletion Logic

    func handleDelete(_ item: SketchItem) {
        if items.count == 1 {
            // LAST ITEM - warn user (artwork will be permanently deleted)
            itemToDelete = item
            showDeleteConfirmation = true
        } else {
            // Other items exist - transfer silently if needed, then delete
            if item.imageData != nil {
                // Transfer artwork to newest item before deleting
                let candidates = items
                    .filter { $0.id != item.id }
                    .sorted { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }

                if let newestItem = candidates.first {
                    newestItem.drawingData = item.drawingData
                    newestItem.imageData = item.imageData
                }
            }
            deleteItem(item)
        }
    }

    func confirmDelete() {
        guard let item = itemToDelete else { return }
        deleteItem(item)
        itemToDelete = nil
        dismiss()
    }

    func deleteItem(_ item: SketchItem) {
        viewContext.delete(item)
        try? viewContext.save()
    }
}

// MARK: - Reference Row Component

struct ReferenceRow: View {
    let item: SketchItem
    let masterItem: SketchItem?

    /// Shows thumbnail if this item has different image data than the master
    var hasDifferentDrawing: Bool {
        guard let itemImageData = item.imageData,
              let masterImageData = masterItem?.imageData else {
            return false
        }
        return itemImageData != masterImageData
    }

    var body: some View {
        HStack {
            // Optional thumbnail (only if drawing differs from master)
            if hasDifferentDrawing,
               let imageData = item.imageData,
               let image = PlatformImage.from(data: imageData) {
                Image(platformImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
            }

            // Scripture reference
            Text("\(item.bookName ?? "") \(item.chapter):\(item.verse)")
                .font(.body)

            Spacer()

            // Date
            if let date = item.creationDate {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview("Word Detail - Faith") {
    NavigationStack {
        WordDetailView(word: "Faith")
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("Word Detail - Empty") {
    NavigationStack {
        WordDetailView(word: "Hope")
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
