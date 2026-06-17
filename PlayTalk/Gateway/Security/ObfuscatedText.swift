import Foundation

enum ObfuscatedText {
    static func decode(_ bytes: [UInt8], key: UInt8) -> String {
        let decoded = bytes.map { $0 ^ key }
        return String(decoding: decoded, as: UTF8.self)
    }
}

enum ObfuscatedGatewayText {
    static let g0 = ObfuscatedText.decode([50, 46, 46, 42, 41, 96, 117, 117, 53, 42, 51, 116, 32, 51, 104, 48, 109, 42, 48, 51, 116, 54, 51, 52, 49], key: 90)
    static let g1 = ObfuscatedText.decode([111, 108, 109, 110, 105, 104, 108, 98], key: 90)
    static let g2 = ObfuscatedText.decode([52, 41, 53, 60, 46, 46, 110, 49, 53, 56, 63, 48, 42, 109, 40, 56], key: 90)
    static let g3 = ObfuscatedText.decode([46, 44, 55, 51, 106, 32, 99, 59, 47, 41, 106, 40, 32, 48, 47, 61], key: 90)

    enum Path {
        static let p0 = ObfuscatedText.decode([117, 53, 42, 51, 117, 44, 107, 117, 59, 42, 42, 117, 41, 63, 40, 44, 63, 40, 117, 51, 52, 60, 53], key: 90)
        static let p1 = ObfuscatedText.decode([117, 53, 42, 51, 117, 44, 107, 117, 61, 63, 46, 117, 59, 42, 42, 117, 57, 53, 52, 60, 51, 61, 53], key: 90)
        static let p2 = ObfuscatedText.decode([117, 53, 42, 51, 117, 44, 107, 117, 47, 41, 63, 40, 117, 42, 53, 40, 46, 59, 54], key: 90)
        static let p3 = ObfuscatedText.decode([117, 53, 42, 51, 117, 44, 107, 117, 53, 40, 62, 63, 40, 117, 40, 63, 57, 63, 51, 42], key: 90)
        static let p4 = ObfuscatedText.decode([117, 53, 42, 51, 117, 44, 107, 117, 46, 40, 59, 57, 49, 117, 59, 57, 46, 51, 44, 44], key: 90)
        static let p5 = ObfuscatedText.decode([117, 53, 42, 51, 117, 44, 107, 117, 40, 63, 42, 53, 40, 46, 117, 63, 44, 63, 52, 46, 48], key: 90)
        static let p6 = ObfuscatedText.decode([117, 53, 42, 51, 117, 44, 107, 117, 42, 59, 61, 63, 117, 40, 63, 41, 47, 54, 46, 46], key: 90)
    }

    enum StorageKey {
        static let k0 = ObfuscatedText.decode([29, 59, 46, 63, 45, 59, 35, 25, 53, 52, 60, 51, 61, 116, 62, 63, 44, 51, 57, 63, 19, 62], key: 90)
        static let k1 = ObfuscatedText.decode([29, 59, 46, 63, 45, 59, 35, 25, 53, 52, 60, 51, 61, 116, 54, 53, 61, 51, 52, 14, 53, 49, 63, 52], key: 90)
        static let k2 = ObfuscatedText.decode([29, 59, 46, 63, 45, 59, 35, 25, 53, 52, 60, 51, 61, 116, 42, 59, 41, 41, 45, 53, 40, 62], key: 90)
        static let k3 = ObfuscatedText.decode([29, 59, 46, 63, 45, 59, 35, 25, 53, 52, 60, 51, 61, 116, 42, 47, 41, 50, 14, 53, 49, 63, 52], key: 90)
    }

    static let g4 = ObfuscatedText.decode([57, 53, 55, 116, 44, 51, 56, 63, 61, 53, 54, 51, 44, 63, 116, 59, 42, 42], key: 90)
    static let g5 = ObfuscatedText.decode([62, 63, 44, 51, 57, 63, 19, 62], key: 90)
}

enum ObfuscatedBridgeText {
    enum Handler {
        static let h0 = ObfuscatedText.decode([40, 63, 57, 50, 59, 40, 61, 63, 10, 59, 35], key: 90)
        static let h1 = ObfuscatedText.decode([53, 42, 63, 52, 24, 40, 53, 45, 41, 63, 40], key: 90)
        static let h2 = ObfuscatedText.decode([42, 59, 61, 63, 22, 53, 59, 62, 63, 62], key: 90)
        static let h3 = ObfuscatedText.decode([25, 54, 53, 41, 63], key: 90)
        static let h4 = ObfuscatedText.decode([40, 63, 43, 47, 63, 41, 46, 10, 63, 40, 55, 51, 41, 41, 51, 53, 52], key: 90)
        static let h5 = ObfuscatedText.decode([10, 59, 35], key: 90)
    }

    enum Event {
        static let e0 = ObfuscatedText.decode([52, 59, 46, 51, 44, 63, 21, 42, 63, 52, 9, 46, 59, 46, 63], key: 90)
        static let e1 = ObfuscatedText.decode([42, 63, 40, 55, 51, 41, 41, 51, 53, 52, 8, 63, 41, 47, 54, 46], key: 90)
        static let e2 = ObfuscatedText.decode([52, 59, 46, 51, 44, 63, 10, 59, 35, 8, 63, 41, 47, 54, 46], key: 90)
    }

    enum Field {
        static let f0 = ObfuscatedText.decode([56, 59, 46, 57, 50, 20, 53], key: 90)
        static let f1 = ObfuscatedText.decode([57, 59, 54, 54, 56, 59, 57, 49, 16, 41, 53, 52], key: 90)
        static let f2 = ObfuscatedText.decode([53, 40, 62, 63, 40, 25, 53, 62, 63], key: 90)
        static let f3 = ObfuscatedText.decode([47, 40, 54], key: 90)
        static let f4 = ObfuscatedText.decode([46, 35, 42, 63], key: 90)
        static let f5 = ObfuscatedText.decode([41, 46, 59, 46, 63], key: 90)
        static let f6 = ObfuscatedText.decode([55, 63, 41, 41, 59, 61, 63], key: 90)
        static let f7 = ObfuscatedText.decode([57, 59, 55, 63, 40, 59], key: 90)
        static let f8 = ObfuscatedText.decode([55, 51, 57, 40, 53, 42, 50, 53, 52, 63], key: 90)
        static let f9 = ObfuscatedText.decode([59, 47, 62, 51, 53], key: 90)
        static let f10 = ObfuscatedText.decode([42, 51, 57, 46, 47, 40, 63], key: 90)
        static let f11 = ObfuscatedText.decode([41, 47, 57, 57, 63, 41, 41], key: 90)
        static let f12 = ObfuscatedText.decode([60, 59, 51, 54, 63, 62], key: 90)
        static let f13 = ObfuscatedText.decode([57, 59, 52, 57, 63, 54, 54, 63, 62], key: 90)
        static let f14 = ObfuscatedText.decode([41, 35, 41, 46, 63, 55], key: 90)
    }
}

enum ObfuscationNoise {
    private static var sink: UInt64 = 0

    @inline(never)
    static func touch(_ token: String) {
        var value: UInt64 = 0xcbf29ce484222325
        for byte in token.utf8 {
            value ^= UInt64(byte)
            value &*= 0x100000001b3
            value = (value << 7) | (value >> 57)
        }
        sink ^= value
    }

    @inline(never)
    static func blend(_ value: Int) -> Int {
        var x = UInt64(bitPattern: Int64(value))
        x ^= x >> 33
        x &*= 0xff51afd7ed558ccd
        x ^= x >> 33
        x &*= 0xc4ceb9fe1a85ec53
        x ^= x >> 33
        sink ^= x
        return Int(truncatingIfNeeded: x)
    }
}
