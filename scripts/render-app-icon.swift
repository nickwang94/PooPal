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
                    LinearGradient(colors: [Color(hex: 0xFFD45E), Color(hex: 0xFFC23A), Color(hex: 0xF7A91F)], startPoint: .top, endPoint: .bottom)
                    RadialGradient(colors: [.white.opacity(0.22), .clear], center: UnitPoint(x: 0.3, y: 0.15), startRadius: 0, endRadius: 620)
                }
            case .dark:
                LinearGradient(colors: [Color(hex: 0x2A2130), Color(hex: 0x17111B)], startPoint: .top, endPoint: .bottom)
            case .tinted:
                Color.black
            }
        }
    }

    private var letterColor: Color {
        switch variant {
        case .standard: Color(hex: 0x4A2A63)
        case .dark: Color(hex: 0xFFC83D)
        case .tinted: Color(white: 0.92)
        }
    }

    var body: some View {
        ZStack {
            background
            Logotype(layout: .line, color: letterColor, eyes: true)
                .frame(width: 870)
                .offset(y: 8)
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
