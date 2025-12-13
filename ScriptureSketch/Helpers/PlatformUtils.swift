import SwiftUI

#if os(macOS)
import AppKit
public typealias PlatformImage = NSImage
public typealias ViewRepresentable = NSViewRepresentable

extension Image {
    init(platformImage: PlatformImage) {
        self.init(nsImage: platformImage)
    }
}

extension NSImage {
    func pngData() -> Data? {
        guard let tiffRepresentation = tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
}

#else
import UIKit
public typealias PlatformImage = UIImage
public typealias ViewRepresentable = UIViewRepresentable

extension Image {
    init(platformImage: PlatformImage) {
        self.init(uiImage: platformImage)
    }
}
#endif

extension PlatformImage {
    static func from(data: Data) -> PlatformImage? {
        return PlatformImage(data: data)
    }
}
