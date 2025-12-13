import SwiftUI

struct MetadataFormView: View {
    // Core Data Context not strictly needed here, but passed if we were editing.
    // However, this form is mostly for creating *new* metadata state to pass to the Editor.
    
    @Binding var book: String
    @Binding var chapter: Int
    @Binding var verse: String // String input for user convenience, converted to Int later
    @Binding var word: String
    @Binding var textColor: String
    
    @State private var selectedBookIndex: Int = 0 
    @State private var availableChapters: [Int] = []
    @State private var availableVerses: [Int] = []
    
    // Internal state for verse integer to bind to picker, since `verse` binding is String
    @State private var selectedVerseInt: Int = 1
    
    // Validation
    var isValid: Bool {
        return !book.isEmpty && 
               !word.isEmpty && 
               BibleDataStore.shared.validate(book: book, chapter: chapter, verse: selectedVerseInt)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Group {
                        Text("Scripture Reference")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // "Slot Machine" Style Pickers
                        HStack(spacing: 0) {
                            // BOOK WHEEL
                            Picker("Book", selection: $selectedBookIndex) {
                                ForEach(BibleDataStore.shared.books) { bookItem in
                                    Text(bookItem.name)
                                        .tag(bookItem.id - 1)
                                        .font(.system(size: 14)) // adjust size to fit
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
                            .onChange(of: selectedVerseInt) { _, newValue in
                                verse = "\(newValue)"
                            }
                        }
                        .frame(height: 150)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    Group {
                        Text("The Icon Word")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("Center Word (e.g. Faith)", text: $word)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("Text Color", selection: $textColor) {
                            Text("Black").tag("black")
                            Text("White").tag("white")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    NavigationLink(destination: DrawingEditorView(
                        book: book,
                        chapter: chapter,
                        verse: selectedVerseInt,
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
                // Initialize based on current bible data
                if availableChapters.isEmpty {
                    updateBookData(index: selectedBookIndex)
                }
            }
        }
    }
    
    // Helpers
    func updateBookData(index: Int) {
        let bookData = BibleDataStore.shared.books[index]
        book = bookData.name
        availableChapters = Array(1...bookData.chapterCount)
        
        // Reset Chapter if needed, or keep if valid (though usually distinct for diff books)
        // Simplest: Reset to 1 on book change
        chapter = 1
        
        updateVerseData(bookIndex: index, chapter: 1)
    }
    
    func updateVerseData(bookIndex: Int, chapter: Int) {
        let bookData = BibleDataStore.shared.books[bookIndex]
        // Safe check
        guard chapter >= 1 && chapter <= bookData.chapterCount else { return }
        
        let vCount = bookData.verseCounts[chapter - 1]
        availableVerses = Array(1...vCount)
        
        // Reset Verse if needed
        selectedVerseInt = 1
        verse = "1"
    }
}
