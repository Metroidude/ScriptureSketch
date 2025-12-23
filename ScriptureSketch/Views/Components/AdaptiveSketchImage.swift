import SwiftUI

struct AdaptiveSketchImage: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var item: SketchItem
    
    var body: some View {
        Group {
            if let platformImage = currentImage {
                Image(platformImage: platformImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            } else {
                // Fallback placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .aspectRatio(1, contentMode: .fill)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    )
            }
        }
    }
    
    // Computed property to pick the right image
    private var currentImage: PlatformImage? {
        if colorScheme == .dark, let darkData = item.effectiveImageDataDark {
            return PlatformImage.from(data: darkData)
        } else if let lightData = item.effectiveImageData {
            return PlatformImage.from(data: lightData)
        }
        return nil
    }
}
