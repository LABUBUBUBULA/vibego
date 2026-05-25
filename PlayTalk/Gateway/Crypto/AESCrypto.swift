import Foundation
import CommonCrypto

/// AES/CBC/PKCS5 加解密工具 - Hex 编码
/// Key: 9986sdff5s4f1123  IV: 9986sdff5s4y456a
struct AESCrypto {

    private static let key = GatewayConfig.aesKey
    private static let iv  = GatewayConfig.aesIV

    // MARK: - 加密

    /// 将明文 JSON 字符串加密为 Hex 字符串
    static func encrypt(_ plainText: String) -> String? {
        guard let data = plainText.data(using: .utf8),
              let keyData = key.data(using: .utf8),
              let ivData = iv.data(using: .utf8) else { return nil }

        let bufferSize = data.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var numBytesEncrypted: size_t = 0

        let status = buffer.withUnsafeMutableBytes { bufferPtr in
            data.withUnsafeBytes { dataPtr in
                keyData.withUnsafeBytes { keyPtr in
                    ivData.withUnsafeBytes { ivPtr in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyPtr.baseAddress, kCCKeySizeAES128,
                            ivPtr.baseAddress,
                            dataPtr.baseAddress, data.count,
                            bufferPtr.baseAddress, bufferSize,
                            &numBytesEncrypted
                        )
                    }
                }
            }
        }

        guard status == kCCSuccess else { return nil }
        let encrypted = buffer.prefix(numBytesEncrypted)
        return encrypted.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - 解密

    /// 将 Hex 字符串解密为明文 JSON 字符串
    static func decrypt(_ hexString: String) -> String? {
        guard let data = hexStringToData(hexString),
              let keyData = key.data(using: .utf8),
              let ivData = iv.data(using: .utf8) else { return nil }

        let bufferSize = data.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var numBytesDecrypted: size_t = 0

        let status = buffer.withUnsafeMutableBytes { bufferPtr in
            data.withUnsafeBytes { dataPtr in
                keyData.withUnsafeBytes { keyPtr in
                    ivData.withUnsafeBytes { ivPtr in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyPtr.baseAddress, kCCKeySizeAES128,
                            ivPtr.baseAddress,
                            dataPtr.baseAddress, data.count,
                            bufferPtr.baseAddress, bufferSize,
                            &numBytesDecrypted
                        )
                    }
                }
            }
        }

        guard status == kCCSuccess else { return nil }
        let decrypted = buffer.prefix(numBytesDecrypted)
        return String(data: decrypted, encoding: .utf8)
    }

    // MARK: - 辅助

    /// Hex 字符串转 Data
    private static func hexStringToData(_ hex: String) -> Data? {
        let len = hex.count
        guard len % 2 == 0 else { return nil }

        var data = Data(capacity: len / 2)
        var index = hex.startIndex
        for _ in 0..<(len / 2) {
            let nextIndex = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<nextIndex], radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        return data
    }

    /// 加密字典为 Hex 字符串
    static func encryptJSON(_ dict: [String: Any]) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return nil }
        return encrypt(jsonString)
    }

    /// 解密 Hex 字符串为字典
    static func decryptToJSON(_ hexString: String) -> [String: Any]? {
        guard let jsonString = decrypt(hexString),
              let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return dict
    }
}
