// Checks a Sparkle EdDSA signature against the public key the app ships with.
// Usage: swift scripts/verify-signature.swift <base64 public key> <base64 signature> <file>
import CryptoKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 4,
    let keyData = Data(base64Encoded: arguments[1]),
    let signature = Data(base64Encoded: arguments[2]),
    let key = try? Curve25519.Signing.PublicKey(rawRepresentation: keyData)
else {
    FileHandle.standardError.write(Data("Usage: verify-signature.swift <public key> <signature> <file>\n".utf8))
    exit(2)
}
let file = try Data(contentsOf: URL(fileURLWithPath: arguments[3]))
guard key.isValidSignature(signature, for: file) else {
    FileHandle.standardError.write(Data("The signature doesn't match SUPublicEDKey: wrong private key?\n".utf8))
    exit(1)
}
