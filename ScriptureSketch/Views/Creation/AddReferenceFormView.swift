import SwiftUI
import CoreData

/// Simplified form for linking a new verse reference to an existing drawing.
/// Only shows scripture picker - the word and drawing are pre-determined.
struct AddReferenceFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    /// The word to link (pre-set, read-only display)
    let word: String

    /// The sharedDrawingId to link to
    let sharedDrawingId: UUID?

    // Scripture selection state
    @State private var selectedBookIndex: Int = 0
    @State private var chapter: Int = 1
    @State private var selectedVerseInt: Int = 1
    @State private var availableChapters: [Int] = []
    @State private var availableVerses: [Int] = []

    var book: String {
        BibleDataStore.shared.books[selectedBookIndex].name
    }

    var isValid: Bool {
        BibleDataStore.shared.validate(book: book, chapter: chapter, verse: selectedVerseInt)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Word Display (read-only)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Linking verse to artwork:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(word)
                            .font(.title2)
                            .bold()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                    // Scripture Picker
                    Group {
                        Text("Scripture Reference")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 0) {
                            // BOOK WHEEL
                            Picker("Book", selection: $selectedBookIndex) {
                                ForEach(BibleDataStore.shared.books) { bookItem in
                                    Text(bookItem.name)
                                        .tag(bookItem.id - 1)
                                        .font(.system(size: 14))
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 140)
                            .clipped()
                            .onChange(of: selectedBookIndex) { _, newValue in
                                updateBookData(index: newValue)
                            }

                            // CHAPTER WHEEL
                            Picker("Ch", selection: $chapter) {
                                ForEach(availableChapters, id: \.self) { num in
                                    Text("\(num)").tag(num)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            .clipped()
                            .onChange(of: chapter) { _, newValue in
                                updateVerseData(bookIndex: selectedBookIndex, chapter: newValue)
                            }

                            Text(":")
                                .font(.headline)

                            // VERSE WHEEL
                            Picker("Vs", selection: $selectedVerseInt) {
                                ForEach(availableVerses, id: \.self) { num in
                                    Text("\(num)").tag(num)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            .clipped()
                        }
                        .frame(height: 150)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                    Spacer(minLength: 20)

                    // Link Button
                    Button {
                        saveReference()
                    } label: {
                        Text("Link Verse")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(isValid ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!isValid)
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("Link Verse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if availableChapters.isEmpty {
                    updateBookData(index: selectedBookIndex)
                }
            }
        }
    }

    // MARK: - Save

    func saveReference() {
        let newItem = SketchItem(context: viewContext)
        newItem.id = UUID()
        newItem.creationDate = Date()
        newItem.bookName = book
        newItem.chapter = Int16(chapter)
        newItem.verse = Int16(selectedVerseInt)
        newItem.centerWord = word
        newItem.textColor = "below" // Default layer position (text below drawing)
        newItem.sharedDrawingId = sharedDrawingId
        // Linked items don't store their own drawing - they reference the master
        newItem.drawingData = nil
        newItem.imageData = nil

        // Set book order for sorting
        if let bookData = BibleDataStore.shared.books.first(where: { $0.name == book }) {
            newItem.bookOrder = Int16(bookData.id)
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to save reference: \(error.localizedDescription)")
        }
    }

    // MARK: - Picker Helpers

    func updateBookData(index: Int) {
        let bookData = BibleDataStore.shared.books[index]
        availableChapters = Array(1...bookData.chapterCount)
        chapter = 1
        updateVerseData(bookIndex: index, chapter: 1)
    }

    func updateVerseData(bookIndex: Int, chapter: Int) {
        let bookData = BibleDataStore.shared.books[bookIndex]
        guard chapter >= 1 && chapter <= bookData.chapterCount else { return }

        let vCount = bookData.verseCounts[chapter - 1]
        availableVerses = Array(1...vCount)
        selectedVerseInt = 1
    }
}

// MARK: - Preview

#Preview("Add Reference Form") {
    AddReferenceFormView(
        word: "Faith",
        sharedDrawingId: UUID()
    )
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
