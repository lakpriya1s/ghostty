// Renders KinTerm's brand images from the SwiftUI mark in
// macos/Sources/Features/Branding/KinTermMark.swift. From the repo root:
//
//   swiftc -parse-as-library macos/Sources/Features/Branding/KinTermMark.swift \
//     scripts/render-brand.swift -o /tmp/render-brand && /tmp/render-brand images

import SwiftUI
import AppKit

@MainActor
func write<V: View>(_ view: V, size: CGSize, scale: CGFloat = 1, to path: String, dark: Bool = true) {
    let r = ImageRenderer(content: view.frame(width: size.width, height: size.height)
        .environment(\.colorScheme, dark ? .dark : .light))
    r.scale = scale
    guard let cg = r.cgImage else { fatalError("render failed \(path)") }
    let rep = NSBitmapImageRep(cgImage: cg)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
    print("wrote \(path) \(cg.width)x\(cg.height)")
}

@main
struct Render {
@MainActor static func main() {
    let out = CommandLine.arguments[1]
    // Icon Composer layer: the face to the edges; macOS rounds the icon itself.
    let layer = Canvas { context, size in
        KinTermMark.draw(in: &context, size: size, front: nil, cornerRadius: 0)
    }
    write(layer, size: CGSize(width: 512, height: 512), scale: 2, to: "\(out)/KinTerm.icon/Assets/mark.png")
    // AppIconImage, used in Settings, error screens and the dock tile plugin.
    let set = "\(out)/../macos/Assets.xcassets/AppIconImage.imageset"
    write(KinTermAppIcon(), size: CGSize(width: 256, height: 256), to: "\(set)/macOS-AppIcon-256px-128pt@2x.png")
    write(KinTermAppIcon(), size: CGSize(width: 512, height: 512), to: "\(set)/macOS-AppIcon-512px.png")
    write(KinTermAppIcon(), size: CGSize(width: 1024, height: 1024), to: "\(set)/macOS-AppIcon-1024px.png")
    // Brand images for the README.
    write(KinTermAppIcon(), size: CGSize(width: 256, height: 256), scale: 2, to: "\(out)/kinterm/icon.png")
    // The web page's favicon and touch icon.
    write(KinTermAppIcon(), size: CGSize(width: 256, height: 256), scale: 2, to: "\(out)/../site/icon.png")
    let states: [(String, Color, KinTermMark.Expression)] = [
        ("working", KinTermBrand.blue, .working),
        ("needs-you", Color(red: 0xf5/255, green: 0xa5/255, blue: 0x24/255), .waiting),
        ("done", Color(red: 0x3f/255, green: 0xb9/255, blue: 0x50/255), .done),
        ("error", Color(red: 0xf8/255, green: 0x51/255, blue: 0x49/255), .error),
    ]
    for (name, front, expression) in states {
        write(KinTermAppIcon(front: front, expression: expression), size: CGSize(width: 128, height: 128), scale: 2,
              to: "\(out)/kinterm/icon-\(name).png")
    }
    for dark in [true, false] {
        write(HStack(spacing: 22) { KinTermMark().frame(width: 84, height: 84); KinTermWordmark(size: 64) }.padding(8),
              size: CGSize(width: 440, height: 110), scale: 2, to: "\(out)/kinterm/logo-\(dark ? "dark" : "light").png", dark: dark)
    }
}
}
