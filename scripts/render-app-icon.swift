import AppKit
import SwiftUI

// Renders PooPal/Assets.xcassets/AppIcon.appiconset/AppIcon.png from the in-app mascot.
// Built by scripts/render-app-icon.sh together with Theme.swift and PoopMascot.swift.

struct IconView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.butter, Theme.peach], startPoint: .top, endPoint: .bottom)
            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 820, height: 820)
                .offset(y: 30)
            PoopMascot(expression: .happy)
                .frame(width: 660, height: 660)
                .offset(y: 40)
        }
        .frame(width: 1024, height: 1024)
    }
}

@main
struct RenderIcon {
    @MainActor
    static func main() throws {
        let output = CommandLine.arguments[1]
        let renderer = ImageRenderer(content: IconView())
        renderer.scale = 1
        guard let cgImage = renderer.cgImage else { fatalError("render failed") }

        // App Store icons must be opaque: redraw into an RGB context without alpha.
        let ctx = CGContext(
            data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )!
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
        let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
        try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
        print("wrote \(output)")
    }
}
