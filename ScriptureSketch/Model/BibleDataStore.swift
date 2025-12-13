import Foundation

struct BibleBook: Identifiable, Hashable {
    let id: Int // Canonical order (1-66)
    let name: String
    let chapterCount: Int
}

class BibleDataStore {
    static let shared = BibleDataStore()
    
    let books: [BibleBook]
    
    private init() {
        self.books = [
            // Old Testament
            BibleBook(id: 1, name: "Genesis", chapterCount: 50),
            BibleBook(id: 2, name: "Exodus", chapterCount: 40),
            BibleBook(id: 3, name: "Leviticus", chapterCount: 27),
            BibleBook(id: 4, name: "Numbers", chapterCount: 36),
            BibleBook(id: 5, name: "Deuteronomy", chapterCount: 34),
            BibleBook(id: 6, name: "Joshua", chapterCount: 24),
            BibleBook(id: 7, name: "Judges", chapterCount: 21),
            BibleBook(id: 8, name: "Ruth", chapterCount: 4),
            BibleBook(id: 9, name: "1 Samuel", chapterCount: 31),
            BibleBook(id: 10, name: "2 Samuel", chapterCount: 24),
            BibleBook(id: 11, name: "1 Kings", chapterCount: 22),
            BibleBook(id: 12, name: "2 Kings", chapterCount: 25),
            BibleBook(id: 13, name: "1 Chronicles", chapterCount: 29),
            BibleBook(id: 14, name: "2 Chronicles", chapterCount: 36),
            BibleBook(id: 15, name: "Ezra", chapterCount: 10),
            BibleBook(id: 16, name: "Nehemiah", chapterCount: 13),
            BibleBook(id: 17, name: "Esther", chapterCount: 10),
            BibleBook(id: 18, name: "Job", chapterCount: 42),
            BibleBook(id: 19, name: "Psalms", chapterCount: 150),
            BibleBook(id: 20, name: "Proverbs", chapterCount: 31),
            BibleBook(id: 21, name: "Ecclesiastes", chapterCount: 12),
            BibleBook(id: 22, name: "Song of Solomon", chapterCount: 8),
            BibleBook(id: 23, name: "Isaiah", chapterCount: 66),
            BibleBook(id: 24, name: "Jeremiah", chapterCount: 52),
            BibleBook(id: 25, name: "Lamentations", chapterCount: 5),
            BibleBook(id: 26, name: "Ezekiel", chapterCount: 48),
            BibleBook(id: 27, name: "Daniel", chapterCount: 12),
            BibleBook(id: 28, name: "Hosea", chapterCount: 14),
            BibleBook(id: 29, name: "Joel", chapterCount: 3),
            BibleBook(id: 30, name: "Amos", chapterCount: 9),
            BibleBook(id: 31, name: "Obadiah", chapterCount: 1),
            BibleBook(id: 32, name: "Jonah", chapterCount: 4),
            BibleBook(id: 33, name: "Micah", chapterCount: 7),
            BibleBook(id: 34, name: "Nahum", chapterCount: 3),
            BibleBook(id: 35, name: "Habakkuk", chapterCount: 3),
            BibleBook(id: 36, name: "Zephaniah", chapterCount: 3),
            BibleBook(id: 37, name: "Haggai", chapterCount: 2),
            BibleBook(id: 38, name: "Zechariah", chapterCount: 14),
            BibleBook(id: 39, name: "Malachi", chapterCount: 4),
            
            // New Testament
            BibleBook(id: 40, name: "Matthew", chapterCount: 28),
            BibleBook(id: 41, name: "Mark", chapterCount: 16),
            BibleBook(id: 42, name: "Luke", chapterCount: 24),
            BibleBook(id: 43, name: "John", chapterCount: 21),
            BibleBook(id: 44, name: "Acts", chapterCount: 28),
            BibleBook(id: 45, name: "Romans", chapterCount: 16),
            BibleBook(id: 46, name: "1 Corinthians", chapterCount: 16),
            BibleBook(id: 47, name: "2 Corinthians", chapterCount: 13),
            BibleBook(id: 48, name: "Galatians", chapterCount: 6),
            BibleBook(id: 49, name: "Ephesians", chapterCount: 6),
            BibleBook(id: 50, name: "Philippians", chapterCount: 4),
            BibleBook(id: 51, name: "Colossians", chapterCount: 4),
            BibleBook(id: 52, name: "1 Thessalonians", chapterCount: 5),
            BibleBook(id: 53, name: "2 Thessalonians", chapterCount: 3),
            BibleBook(id: 54, name: "1 Timothy", chapterCount: 6),
            BibleBook(id: 55, name: "2 Timothy", chapterCount: 4),
            BibleBook(id: 56, name: "Titus", chapterCount: 3),
            BibleBook(id: 57, name: "Philemon", chapterCount: 1),
            BibleBook(id: 58, name: "Hebrews", chapterCount: 13),
            BibleBook(id: 59, name: "James", chapterCount: 5),
            BibleBook(id: 60, name: "1 Peter", chapterCount: 5),
            BibleBook(id: 61, name: "2 Peter", chapterCount: 3),
            BibleBook(id: 62, name: "1 John", chapterCount: 5),
            BibleBook(id: 63, name: "2 John", chapterCount: 1),
            BibleBook(id: 64, name: "3 John", chapterCount: 1),
            BibleBook(id: 65, name: "Jude", chapterCount: 1),
            BibleBook(id: 66, name: "Revelation", chapterCount: 22)
        ]
    }
    
    func validate(book: String, chapter: Int) -> Bool {
        guard let bookData = books.first(where: { $0.name == book }) else { return false }
        return chapter >= 1 && chapter <= bookData.chapterCount
    }
}
