import SwiftUI
import CoreGraphics

func perlinNoiseImage(width: Int, height: Int, scale: Double = 0.1, octaves: Int = 6, persistence: Double = 0.5) -> NSImage? {
    var pixels = [UInt8](repeating: 0, count: width * height * 4) // RGBA format

    for y in 0..<height {
        for x in 0..<width {
            let noiseValue = octavePerlin(
                x: Double(x) * scale,
                y: Double(y) * scale,
                z: 0.0,  // Keeping Z constant for a 2D texture
                octaves: octaves,
                persistence: persistence
            )

            // Normalize to [0,255] and clamp to ensure no out-of-bound values
            let color = UInt8(min(max((noiseValue + 1) * 127.5, 0), 255)) // Normalize and clamp to [0,255]
            let index = (y * width + x) * 4

            pixels[index] = color     // Red
            pixels[index + 1] = color // Green
            pixels[index + 2] = color // Blue
            pixels[index + 3] = 255   // Alpha (fully opaque)
        }
    }

    return imageFromPixelData(pixels, width: width, height: height)
}

private func imageFromPixelData(_ pixelData: [UInt8], width: Int, height: Int) -> NSImage? {
    let bitsPerComponent = 8
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    guard let providerRef = CGDataProvider(data: NSData(bytes: pixelData, length: pixelData.count)) else {
        return nil
    }

    guard let cgImage = CGImage(
        width: width,
        height: height,
        bitsPerComponent: bitsPerComponent,
        bitsPerPixel: bytesPerPixel * 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)),
        provider: providerRef,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    ) else {
        return nil
    }

    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()
    NSGraphicsContext.current?.cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    image.unlockFocus()

    return image
}

