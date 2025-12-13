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
    
    // Validation
    var isValid: Bool {
        return !book.isEmpty && 
               !word.isEmpty && 
               Int(verse) != nil &&
               BibleDataStore.shared.validate(book: book, chapter: chapter)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Scripture Reference")) {
                    Picker("Book", selection: $selectedBookIndex) {
                        ForEach(BibleDataStore.shared.books) { bookItem in
                            Text(bookItem.name).tag(bookItem.id - 1) // 0-based index
                        }
                    }
                    .onChange(of: selectedBookIndex) { newValue in
                        updateBookAndChapters(index: newValue)
                    }
                    
                    Picker("Chapter", selection: $chapter) {
                        ForEach(availableChapters, id: \.self) { num in
                            Text("\(num)").tag(num)
                        }
                    }
                    
                    HStack {
                        Text("Verse")
                        TextField("#", text: $verse)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("The Icon Word")) {
                    TextField("Center Word (e.g. Faith)", text: $word)
                    
                    Picker("Text Color", selection: $textColor) {
                        Text("Black").tag("black")
                        Text("White").tag("white")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    NavigationLink(destination: DrawingEditorView(
                        book: book,
                        chapter: chapter,
                        verse: Int(verse) ?? 1,
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
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("New Sketch")
            .onAppear {
                // Initialize state if needed
                if availableChapters.isEmpty {
                    updateBookAndChapters(index: 0)
                }
            }
        }
    }
    
    // Helpers
    func updateBookAndChapters(index: Int) {
        let bookData = BibleDataStore.shared.books[index]
        book = bookData.name
        availableChapters = Array(1...bookData.chapterCount)
        // Reset chapter if out of bounds (though picker usually handles this, safe to be sure)
        chapter = 1
    }
}
