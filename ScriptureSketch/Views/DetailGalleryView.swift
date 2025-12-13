import SwiftUI

struct DetailGalleryView: View {
    var items: [SketchItem]
    var title: String
    var contextMode: MainCatalogView.ViewMode // To know what caption to show
    
    let columns = [GridItem(.adaptive(minimum: 150))]
    
    var body: some View {
        Group {
            if contextMode == .word {
                // Word Mode: Accordion List
                List(items) { item in
                    DisclosureGroup {
                        if let imageData = item.imageData, let platformImage = PlatformImage.from(data: imageData) {
                            Image(platformImage: platformImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(8)
                                .frame(height: 250) // Limit height of expanded view
                                .frame(maxWidth: .infinity)
                                .padding(.vertical)
                            
                            // Edit Button access?
                            // For now, just showing the content as requested.
                            // Could add a NavigationLink here if full detailed edit is needed.
                            NavigationLink("View Details / Edit", destination: SingleItemDetailView(item: item))
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    } label: {
                        Text("\(item.bookName ?? "") \(item.chapter):\(item.verse)")
                            .font(.headline)
                    }
                }
                .listStyle(.plain)
            } else {
                // Scripture Mode: Carousel (Single Verse, multiple Words)
                // Use TabView for Page/Carousel feel
                TabView {
                    ForEach(items) { item in
                        VStack {
                            if let imageData = item.imageData, let platformImage = PlatformImage.from(data: imageData) {
                                Image(platformImage: platformImage)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(12)
                                    .shadow(radius: 5)
                                    .padding()
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .overlay(Text("No Image"))
                            }
                            
                            // The varying factor here is the "Word"
                            Text(item.centerWord ?? "?")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.primary)
                            
                            NavigationLink("View Details", destination: SingleItemDetailView(item: item))
                                .padding(.top)
                        }
                        .padding()
                        .tag(item.id) // Tag for identification
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .background(Color.gray.opacity(0.1)) // Subtle background for the carousel area
            }
        }
        .navigationTitle(title)
    }
}
