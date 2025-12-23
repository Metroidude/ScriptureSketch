import SwiftUI

struct MetadataFormView: View {
    // External bindings for final values
    @Binding var book: String
    @Binding var chapter: Int
    @Binding var verse: String
    @Binding var word: String
    @Binding var textColor: String

    // Optional parameter to pre-fill scripture fields
    var lockedScripture: (book: String, chapter: Int, verse: Int)? = nil

    // ALL picker state is internal - we sync to bindings via onChange
    @State private var selectedBookIndex: Int
    @State private var selectedChapter: Int
    @State private var selectedVerse: Int
    @State private var availableChapters: [Int]
    @State private var availableVerses: [Int]

    // Focus state for auto-focusing word field when scripture is locked
    @FocusState private var isWordFieldFocused: Bool

    // Custom init to properly initialize all state
    init(
        book: Binding<String>,
        chapter: Binding<Int>,
        verse: Binding<String>,
        word: Binding<String>,
        textColor: Binding<String>,
        lockedScripture: (book: String, chapter: Int, verse: Int)? = nil
    ) {
        self._book = book
        self._chapter = chapter
        self._verse = verse
        self._word = word
        self._textColor = textColor
        self.lockedScripture = lockedScripture

        // Determine initial values from lockedScripture or defaults
        let initialBookIndex: Int
        let initialChapter: Int
        let initialVerse: Int
        let chapters: [Int]
        let verses: [Int]

        if let locked = lockedScripture,
           let bookData = BibleDataStore.shared.books.first(where: { $0.name == locked.book }) {
            // Pre-fill with locked scripture values
            initialBookIndex = bookData.id - 1
            initialChapter = locked.chapter
            initialVerse = locked.verse
            chapters = Array(1...bookData.chapterCount)
            let verseCount = (locked.chapter >= 1 && locked.chapter <= bookData.chapterCount)
                ? bookData.verseCounts[locked.chapter - 1]
                : 1
            verses = Array(1...verseCount)
        } else {
            // Default initialization (Genesis 1:1)
            let genesisData = BibleDataStore.shared.books[0]
            initialBookIndex = 0
            initialChapter = 1
            initialVerse = 1
            chapters = Array(1...genesisData.chapterCount)
            verses = Array(1...genesisData.verseCounts[0])
        }

        self._selectedBookIndex = State(initialValue: initialBookIndex)
        self._selectedChapter = State(initialValue: initialChapter)
        self._selectedVerse = State(initialValue: initialVerse)
        self._availableChapters = State(initialValue: chapters)
        self._availableVerses = State(initialValue: verses)
    }

    // Validation
    var isValid: Bool {
        return !book.isEmpty &&
               !word.isEmpty &&
               BibleDataStore.shared.validate(book: book, chapter: selectedChapter, verse: selectedVerse)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Group {
                        Text("Scripture Reference")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // "Slot Machine" Style Pickers (always editable)
                        HStack(spacing: 0) {
                            // BOOK WHEEL
                            Picker("Book", selection: $selectedBookIndex) {
                                ForEach(0..<BibleDataStore.shared.books.count, id: \.self) { index in
                                    Text(BibleDataStore.shared.books[index].name)
                                        .tag(index)
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
                            Picker("Ch", selection: $selectedChapter) {
                                ForEach(availableChapters, id: \.self) { num in
                                    Text("\(num)").tag(num)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            .clipped()
                            .onChange(of: selectedChapter) { _, newValue in
                                updateVerseData(bookIndex: selectedBookIndex, chapter: newValue)
                            }

                            Text(":")
                                .font(.headline)

                            // VERSE WHEEL
                            Picker("Vs", selection: $selectedVerse) {
                                ForEach(availableVerses, id: \.self) { num in
                                    Text("\(num)").tag(num)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            .clipped()
                            .onChange(of: selectedVerse) { _, newValue in
                                syncBindings()
                            }
                        }
                        .frame(height: 150)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    Group {
                        Text("The Keyword")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField("Grace, Faith, etc.", text: $word)
                            .textFieldStyle(.roundedBorder)
                            .focused($isWordFieldFocused)
                        
                        Picker("Text Layer", selection: $textColor) {
                            Text("Text Below").tag("below")
                            Text("Text On Top").tag("top")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    NavigationLink(destination: DrawingEditorView(
                        book: BibleDataStore.shared.books[selectedBookIndex].name,
                        chapter: selectedChapter,
                        verse: selectedVerse,
                        word: word,
                        textColor: textColor
                    )) {
                        Text("Next: Draw Icon")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(isValid ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!isValid)
                    .buttonStyle(.plain) // Important for macOS to not look like a link text
                }
                .padding()
            }
            .navigationTitle("New Sketch")
            .onAppear {
                // Sync bindings with internal state on appear
                syncBindings()

                // Auto-focus word field when scripture is pre-filled
                if lockedScripture != nil {
                    isWordFieldFocused = true
                }
            }
        }
    }
    
    // MARK: - Helpers

    func syncBindings() {
        book = BibleDataStore.shared.books[selectedBookIndex].name
        chapter = selectedChapter
        verse = "\(selectedVerse)"
    }

    func updateBookData(index: Int) {
        let bookData = BibleDataStore.shared.books[index]
        availableChapters = Array(1...bookData.chapterCount)

        // Reset chapter to 1 on book change
        selectedChapter = 1
        updateVerseData(bookIndex: index, chapter: 1)
    }

    func updateVerseData(bookIndex: Int, chapter: Int) {
        let bookData = BibleDataStore.shared.books[bookIndex]
        guard chapter >= 1 && chapter <= bookData.chapterCount else { return }

        let vCount = bookData.verseCounts[chapter - 1]
        availableVerses = Array(1...vCount)

        // Reset verse to 1 if current selection is out of range
        if selectedVerse > vCount {
            selectedVerse = 1
        }
        syncBindings()
    }
}
