import Foundation
import Accelerate

func octavePerlin(x: Double, y: Double, z: Double, octaves: Int, persistence: Double) -> Double {
    var total: Double = 0
    var frequency: Double = 1
    var amplitude: Double = 1
    var maxValue: Double = 0
    
    for _ in 0..<octaves {
        total += perlinNoise(x: x * frequency, y: y * frequency, z: z * frequency) * amplitude
        maxValue += amplitude
        amplitude *= persistence
        frequency *= 2
    }
    
    return total / maxValue
}

func inc(num: Int, repeated: Double) -> Int {
    var incrementedNum = num + 1
    if repeated > 0 {
        incrementedNum = incrementedNum % Int(repeated)
    }
    return incrementedNum
}

func perlinNoise(x: Double, y: Double, z: Double) -> Double {
    var x1 = x
    var y1 = y
    var z1 = z
    let repeated: Double = 3
    
    if repeated > 0 {
        x1 = x.truncatingRemainder(dividingBy: repeated)
        y1 = y.truncatingRemainder(dividingBy: repeated)
        z1 = z.truncatingRemainder(dividingBy: repeated)
    }
    
    let xi = Int(x1) & 255
    let yi = Int(y1) & 255
    let zi = Int(z1) & 255
    let xf = x1 - x.truncatingRemainder(dividingBy: 1)
    let yf = y1 - y.truncatingRemainder(dividingBy: 1)
    let zf = z1 - z.truncatingRemainder(dividingBy: 1)
    
    let u = fade(t: xf)
    let v = fade(t: yf)
    let w = fade(t: zf)
    
    let p = generatePermutations()
    
    let aaa = p[p[p[xi] + yi] + zi]
    let aba = p[p[p[xi] + inc(num: yi, repeated: repeated)] + zi]
    let aab = p[p[p[xi] + yi] + inc(num: zi, repeated: repeated)]
    let abb = p[p[p[xi] + inc(num: yi, repeated: repeated)] + inc(num: zi, repeated: repeated)]
    let baa = p[p[p[inc(num: xi, repeated: repeated)] + yi] + zi]
    let bba = p[p[p[inc(num: xi, repeated: repeated)] + inc(num: yi, repeated: repeated)] + zi]
    let bab = p[p[p[inc(num: xi, repeated: repeated)] + yi] + inc(num: zi, repeated: repeated)]
    let bbb = p[p[p[inc(num: xi, repeated: repeated)] + inc(num: yi, repeated: repeated)] + inc(num: zi, repeated: repeated)]
    
    let x2 = lerp(a: grad(hash: aaa, x: xf, y: yf, z: zf), b: grad(hash: baa, x: xf - 1, y: yf, z: zf), c: u, x: x)
    let x3 = lerp(a: grad(hash: aba, x: xf, y: yf - 1, z: zf), b: grad(hash: bba, x: xf - 1, y: yf - 1, z: zf), c: u, x: x)
    let y2 = lerp(a: x2, b: x3, c: v, x: x)
    
    let x4 = lerp(a: grad(hash: aab, x: xf, y: yf, z: zf - 1), b: grad(hash: bab, x: xf - 1, y: yf, z: zf - 1), c: u, x: x)
    let x5 = lerp(a: grad(hash: abb, x: xf, y: yf - 1, z: zf - 1), b: grad(hash: bbb, x: xf - 1, y: yf - 1, z: zf - 1), c: u, x: x)
    let y3 = lerp(a: x4, b: x5, c: v, x: x)
    
    return (lerp(a: y2, b: y3, c: w, x: x) + 1) / 2
}

func grad(hash: Int, x: Double, y: Double, z: Double) -> Double {
    let h = hash & 15
    let u = h < 8 ? x : y
    var v: Double
    
    if h < 4 {
        v = y
    } else if h == 12 || h == 14 {
        v = x
    } else {
        v = z
    }
    
    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
}

func lerp(a: Double, b: Double, c: Double, x: Double) -> Double {
    return a + x * (b - a)
}

func fade(t: Double) -> Double {
    return t * t * t * (t * (t * 6 - 15) + 10)
}

func generatePermutations() -> [Int] {
    let permutations: [Int] = [151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180]
    var p = [Int](repeating: 0, count: 512)
    for i in 0..<256 {
        p[i] = permutations[i]
        p[i + 256] = permutations[i]
    }
    return p
}
