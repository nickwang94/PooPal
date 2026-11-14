import AppKit
import SwiftUI

// Renders the PooPal app icon (default, dark, tinted) from the in-app Logotype.
// Built by scripts/render-app-icon.sh together with Theme.swift and Logotype.swift.

enum Variant: String, CaseIterable {
    case standard = "AppIcon"
    case dark = "AppIcon-Dark"
    case tinted = "AppIcon-Tinted"
}

struct IconView: View {
    let variant: Variant

    private var background: some View {
        Group {
            switch variant {
            case .standard:
                ZStack {
                    Color(hex: 0x0F5F59)
                    // Glaze: the same soft top highlight as the in-app tiles.
                    LinearGradient(colors: [.white.opacity(0.12), .clear], startPoint: .top, endPoint: .center)
                }
            case .dark:
                LinearGradient(colors: [Color(hex: 0x10201E), Color(hex: 0x060D0C)], startPoint: .top, endPoint: .bottom)
            case .tinted:
                Color.black
            }
        }
    }

    private var letterColor: Color {
        switch variant {
        case .standard: Color(hex: 0xF3FBF9)
        case .dark: Color(hex: 0x5EC2B6)
        case .tinted: Color(white: 0.92)
        }
    }

    var body: some View {
        ZStack {
            background
            Logotype(layout: .line, color: letterColor)
                .frame(width: 800)
        }
        .frame(width: 1024, height: 1024)
    }
}

@main
struct RenderIcon {
    @MainActor
    static func main() throws {
        let directory = CommandLine.arguments[1]
        for variant in Variant.allCases {
            let renderer = ImageRenderer(content: IconView(variant: variant))
            renderer.scale = 1
            guard let cgImage = renderer.cgImage else { fatalError("render failed") }
            // App icons must be opaque: redraw into an RGB context without alpha.
            let ctx = CGContext(
                data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )!
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
            let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
            let url = URL(fileURLWithPath: directory).appending(path: "\(variant.rawValue).png")
            try rep.representation(using: .png, properties: [:])!.write(to: url)
            print("wrote \(url.path)")
        }
    }
}
