import SwiftUI
import CoreData

struct MainCatalogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    enum ViewMode: String, CaseIterable {
        case scripture = "Scripture"
        case word = "Word"
    }
    
    @State private var viewMode: ViewMode = .scripture
    @State private var searchText = ""
    @State private var showingCreationSheet = false
    
    // Fetch all items initially, then we filter/group in memory for the Directory feel.
    // Optimizing this for millions of items would require smarter FetchRequests, 
    // but for personal use, fetching all metadata is okay.
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.creationDate, order: .reverse)],
        animation: .default)
    private var allItems: FetchedResults<SketchItem>
    
    var filteredItems: [SketchItem] {
        if searchText.isEmpty {
            return Array(allItems)
        } else {
            return allItems.filter { item in
                let wordMatch = item.centerWord?.localizedCaseInsensitiveContains(searchText) ?? false
                let bookMatch = item.bookName?.localizedCaseInsensitiveContains(searchText) ?? false
                let verseMatch_Legacy = "\(item.chapter):\(item.verse)".contains(searchText)
                return wordMatch || bookMatch || verseMatch_Legacy
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if allItems.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Sketches yet.\nTap + to begin.")
                            .multilineTextAlignment(.center)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        if viewMode == .scripture {
                            // Unique Verse Aggregation
                            // Group by "Book Chapter:Verse"
                            let grouped = Dictionary(grouping: filteredItems) { item -> String in
                                // Sorting Key logic needed? 
                                // We want to display: "Genesis 1:1"
                                // We need to sort by Canonical Order.
                                return "\(item.bookName ?? "")|\(item.bookOrder)|\(item.chapter)|\(item.verse)"
                            }
                            
                            // Sort keys
                            let sortedKeys = grouped.keys.sorted { key1, key2 in
                                let parts1 = key1.split(separator: "|")
                                let parts2 = key2.split(separator: "|")
                                
                                // Safety check
                                guard parts1.count == 4, parts2.count == 4 else { return key1 < key2 }
                                
                                let order1 = Int(parts1[1]) ?? 0
                                let order2 = Int(parts2[1]) ?? 0
                                if order1 != order2 { return order1 < order2 }
                                
                                let ch1 = Int(parts1[2]) ?? 0
                                let ch2 = Int(parts2[2]) ?? 0
                                if ch1 != ch2 { return ch1 < ch2 }
                                
                                let v1 = Int(parts1[3]) ?? 0
                                let v2 = Int(parts2[3]) ?? 0
                                return v1 < v2
                            }
                            
                            ForEach(sortedKeys, id: \.self) { key in
                                let parts = key.split(separator: "|")
                                let displayName = "\(parts[0]) \(parts[2]):\(parts[3])"
                                let itemsForVerse = grouped[key] ?? []
                                
                                NavigationLink(destination: DetailGalleryView(items: itemsForVerse, title: displayName, contextMode: .scripture)) {
                                    HStack {
                                        Text(displayName)
                                        Spacer()
                                        Text("\(itemsForVerse.count)")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                        } else {
                            // Word Mode: Unique Center Words
                            let grouped = Dictionary(grouping: filteredItems) { $0.centerWord ?? "Unknown" }
                            let sortedKeys = grouped.keys.sorted()
                            
                            ForEach(sortedKeys, id: \.self) { word in
                                let itemsForWord = grouped[word] ?? []
                                NavigationLink(destination: DetailGalleryView(items: itemsForWord, title: word, contextMode: .word)) {
                                    HStack {
                                        Text(word)
                                        Spacer()
                                        Text("\(itemsForWord.count)")
                                            .foregroundColor(.secondary)
                                        
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("Mode", selection: $viewMode) {
                        Text("Scripture").tag(ViewMode.scripture)
                        Text("Word").tag(ViewMode.word)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingCreationSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreationSheet) {
                // Wrapper to manage state
                BindingMetadataFormWrapper(isPresented: $showingCreationSheet)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DismissCreationSheet"))) { _ in
                showingCreationSheet = false
            }
        }
    }
}

// Wrapper to hold temporary state for the form so we can pass bindings
struct BindingMetadataFormWrapper: View {
    @Binding var isPresented: Bool
    
    @State private var book = "Genesis"
    @State private var chapter = 1
    @State private var verse = ""
    @State private var word = ""
    @State private var textColor = "black"
    
    var body: some View {
        MetadataFormView(
            book: $book,
            chapter: $chapter,
            verse: $verse,
            word: $word,
            textColor: $textColor
        )
    }
}

#Preview {
    MainCatalogView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
