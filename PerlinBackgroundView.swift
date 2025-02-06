import SwiftUI
import CoreGraphics
import Foundation

// MARK: - Noise Color
struct NoiseColor {
    let r: Double
    let g: Double
    let b: Double
    
    func interpolate(with other: NoiseColor, factor: Double) -> (r: UInt8, g: UInt8, b: UInt8) {
        let r = UInt8(((self.r * (1 - factor) + other.r * factor) * 255).clamped(to: 0...255))
        let g = UInt8(((self.g * (1 - factor) + other.g * factor) * 255).clamped(to: 0...255))
        let b = UInt8(((self.b * (1 - factor) + other.b * factor) * 255).clamped(to: 0...255))
        return (r, g, b)
    }
}

// MARK: - Perlin Noise Generator
class PerlinNoiseGenerator {
    // [Previous PerlinNoiseGenerator implementation remains exactly the same]
    private let p: [Int]
    
    init() {
        let permutations: [Int] = [151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180]
        p = permutations + permutations
    }
    
    func noise(x: Double, y: Double, z: Double) -> Double {
        let xi = Int(floor(x)) & 255
        let yi = Int(floor(y)) & 255
        let zi = Int(floor(z)) & 255
        
        let xx = x - floor(x)
        let yy = y - floor(y)
        let zz = z - floor(z)
        
        let u = fade(t: xx)
        let v = fade(t: yy)
        let w = fade(t: zz)
        
        let a  = p[xi] + yi
        let aa = p[a] + zi
        let ab = p[a + 1] + zi
        let b  = p[xi + 1] + yi
        let ba = p[b] + zi
        let bb = p[b + 1] + zi
        
        let result = lerp(
            a: lerp(
                a: lerp(a: grad(hash: p[aa], x: xx, y: yy, z: zz),
                       b: grad(hash: p[ba], x: xx-1, y: yy, z: zz),
                       t: u),
                b: lerp(a: grad(hash: p[ab], x: xx, y: yy-1, z: zz),
                       b: grad(hash: p[bb], x: xx-1, y: yy-1, z: zz),
                       t: u),
                t: v),
            b: lerp(
                a: lerp(a: grad(hash: p[aa+1], x: xx, y: yy, z: zz-1),
                       b: grad(hash: p[ba+1], x: xx-1, y: yy, z: zz-1),
                       t: u),
                b: lerp(a: grad(hash: p[ab+1], x: xx, y: yy-1, z: zz-1),
                       b: grad(hash: p[bb+1], x: xx-1, y: yy-1, z: zz-1),
                       t: u),
                t: v),
            t: w)
        
        return (result + 1) / 2
    }
    
    private func fade(t: Double) -> Double {
        return t * t * t * (t * (t * 6 - 15) + 10)
    }
    
    private func lerp(a: Double, b: Double, t: Double) -> Double {
        return a + t * (b - a)
    }
    
    private func grad(hash: Int, x: Double, y: Double, z: Double) -> Double {
        let h = hash & 15
        let u = h < 8 ? x : y
        let v = h < 4 ? y : (h == 12 || h == 14 ? x : z)
        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
    }
    
    func octaveNoise(x: Double, y: Double, z: Double, octaves: Int, persistence: Double) -> Double {
        var total: Double = 0
        var frequency: Double = 1
        var amplitude: Double = 1
        var maxValue: Double = 0
        
        for _ in 0..<octaves {
            total += noise(x: x * frequency, y: y * frequency, z: z * frequency) * amplitude
            maxValue += amplitude
            amplitude *= persistence
            frequency *= 2
        }
        
        return total / maxValue
    }
}

// MARK: - Image Generation
func generatePerlinNoiseImage(width: Int, height: Int, scale: Double = 0.1, octaves: Int = 6, persistence: Double = 0.5) -> NSImage? {
    let generator = PerlinNoiseGenerator()
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    
    // Base colors with strong tints
    let baseColors = [
        NoiseColor(r: 0.94, g: 0.96, b: 1.0),    // Blue-white
        NoiseColor(r: 0.87, g: 0.92, b: 1.0),    // Stronger blue
        NoiseColor(r: 0.96, g: 0.92, b: 1.0),    // Purple tint
        NoiseColor(r: 1.0, g: 0.94, b: 0.98)     // Pink tint
    ]
    
    // Very vibrant accent flecks
    let accentColors = [
        NoiseColor(r: 1.0, g: 0.7, b: 0.7),      // Bright pink
        NoiseColor(r: 0.7, g: 1.0, b: 0.7),      // Bright green
        NoiseColor(r: 0.7, g: 0.7, b: 1.0),      // Bright blue
        NoiseColor(r: 1.0, g: 0.85, b: 0.7)      // Bright orange
    ]
    
    func calculateNoise(x: Int, y: Int) -> (base: Double, accent: Double) {
        let noiseValue1 = generator.octaveNoise(
            x: Double(x) * scale,
            y: Double(y) * scale,
            z: 0.0,
            octaves: octaves,
            persistence: persistence
        )
        
        let noiseValue2 = generator.octaveNoise(
            x: Double(x) * scale * 6,  // Increased frequency for smaller flecks
            y: Double(y) * scale * 6,
            z: 2.0,
            octaves: max(2, octaves - 2),
            persistence: persistence * 0.7
        )
        
        return (noiseValue1, noiseValue2)
    }
    
    func getColorForNoise(baseNoise: Double, accentNoise: Double) -> (r: UInt8, g: UInt8, b: UInt8) {
        let baseColorIndex = Int(baseNoise * Double(baseColors.count - 1))
        let nextBaseColorIndex = min(baseColorIndex + 1, baseColors.count - 1)
        let baseBlendFactor = baseNoise * Double(baseColors.count - 1) - Double(baseColorIndex)
        
        let baseColor = baseColors[baseColorIndex].interpolate(
            with: baseColors[nextBaseColorIndex],
            factor: baseBlendFactor
        )
        
        if accentNoise > 0.85 {  // Higher threshold for rarer but more intense flecks
            let accentColorIndex = Int(accentNoise * Double(accentColors.count - 1))
            let accentColor = accentColors[accentColorIndex]
            
            let accentStrength = (accentNoise - 0.85) / 0.15 * 0.8  // Stronger effect
            
            return (
                r: UInt8(Double(baseColor.r) * (1 - accentStrength) + accentColor.r * 255 * accentStrength),
                g: UInt8(Double(baseColor.g) * (1 - accentStrength) + accentColor.g * 255 * accentStrength),
                b: UInt8(Double(baseColor.b) * (1 - accentStrength) + accentColor.b * 255 * accentStrength)
            )
        }
        
        return baseColor
    }
    
    DispatchQueue.concurrentPerform(iterations: height) { y in
        for x in 0..<width {
            let (baseNoise, accentNoise) = calculateNoise(x: x, y: y)
            let color = getColorForNoise(baseNoise: baseNoise, accentNoise: accentNoise)
            
            let index = (y * width + x) * 4
            pixels[index] = color.r
            pixels[index + 1] = color.g
            pixels[index + 2] = color.b
            pixels[index + 3] = 255
        }
    }
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
    
    guard let provider = CGDataProvider(data: Data(pixels) as CFData),
          let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
            provider: provider,
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

// [Rest of the code remains exactly the same, including:]
// - extension Comparable
// - func saveNoiseImage
// - func loadNoiseImage
// - struct PerlinNoiseView
// - struct PerlinBackgroundView

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

func saveNoiseImage(_ image: NSImage, to filename: String) -> Bool {
    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = directory.appendingPathComponent(filename).appendingPathExtension("png")
    
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
          let colorSpace = cgImage.colorSpace else {
        return false
    }
    
    guard let imageData = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(image.size.width),
        pixelsHigh: Int(image.size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        return false
    }
    
    imageData.size = image.size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: imageData)
    image.draw(in: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
    NSGraphicsContext.restoreGraphicsState()
    
    guard let data = imageData.representation(using: .png, properties: [:]) else {
        return false
    }
    
    do {
        try data.write(to: fileURL)
        return true
    } catch {
        print("Error saving image: \(error)")
        return false
    }
}

func loadNoiseImage(from filename: String) -> NSImage? {
    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = directory.appendingPathComponent(filename).appendingPathExtension("png")
    
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
        return nil
    }
    
    return NSImage(contentsOf: fileURL)
}

struct PerlinNoiseView: View {
    @State private var noiseImage: NSImage?
    @State private var scale: Double = 0.03
    @State private var octaves: Int = 5
    @State private var persistence: Double = 0.6
    @Environment(\.dismiss) var dismiss
    @State private var showingSaveAlert = false
    @State private var saveResult = false
    
    var body: some View {
        VStack {
            if let image = noiseImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 512, maxHeight: 512)
            }
            
            VStack(spacing: 10) {
                HStack {
                    Text("Scale: \(scale, specifier: "%.3f")")
                    Slider(value: $scale, in: 0.01...0.2) { _ in
                        generateImage()
                    }
                }
                
                HStack {
                    Text("Octaves: \(octaves)")
                    Slider(value: .init(
                        get: { Double(octaves) },
                        set: { octaves = Int($0) }
                    ), in: 1...8) { _ in
                        generateImage()
                    }
                }
                
                HStack {
                    Text("Persistence: \(persistence, specifier: "%.2f")")
                    Slider(value: $persistence, in: 0.1...1.0) { _ in
                        generateImage()
                    }
                }
                
                HStack {
                    Button("Save Image") {
                        if let image = noiseImage {
                            saveResult = saveNoiseImage(image, to: "background")
                            showingSaveAlert = true
                        }
                    }
                    
                    Button("Close") {
                        dismiss()
                    }
                }
                .padding(.top)
            }
            .padding()
        }
        .frame(width: 600, height: 700)
        .onAppear {
            // Try to load existing image first
            if let savedImage = loadNoiseImage(from: "background") {
                noiseImage = savedImage
            } else {
                generateImage()
            }
        }
        .alert("Save Image", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveResult ? "Image saved successfully" : "Failed to save image")
        }
    }
    
    private func generateImage() {
        noiseImage = generatePerlinNoiseImage(
            width: 512,
            height: 512,
            scale: scale,
            octaves: octaves,
            persistence: persistence
        )
    }
}
struct UserAvatarView: View {
    var body: some View {
        Circle()
                    .fill(.white)
                    .frame(width: 200, height: 200)
                    .overlay(
                        Circle()
                            .stroke(Color.gray, lineWidth: 1)
                    ).shadow(color: Color.orange, radius: 3)
    }
}
struct PerlinBackgroundView: View {
    @State private var backgroundImage: NSImage?
    var users: [Int] = [1, 2]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = backgroundImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    Color.white // Fallback color
                }
                HStack {
                    ForEach(users, id: \.self) { _ in
                        UserAvatarView()
                    }
                }
            }
        }
        .onAppear {
            backgroundImage = loadNoiseImage(from: "background")
        }
    }
}


#Preview {
    PerlinNoiseView()
}
