import SwiftUI

struct DetailGalleryView: View {
    var items: [SketchItem]
    var title: String
    var contextMode: MainCatalogView.ViewMode // To know what caption to show
    
    let columns = [GridItem(.adaptive(minimum: 150))]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(items) { item in
                    NavigationLink(destination: SingleItemDetailView(item: item)) {
                        VStack {
                            if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(8)
                                    .shadow(radius: 2)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(Text("?"))
                            }
                            
                            // Contextual Caption
                            if contextMode == .scripture {
                                Text(item.centerWord ?? "?")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.primary)
                            } else {
                                Text("\(item.bookName ?? "") \(item.chapter):\(item.verse)")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(title)
    }
}
