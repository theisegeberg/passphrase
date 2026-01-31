import Foundation

func entropyDescription(bits:Int) -> String {
    switch bits {
        case ..<28:
            return """
                \(bits) bits of entropy is considered very weak. It provides minimal protection and should only be used in non-critical situations where security is not a concern. Avoid using this for any sensitive information or accounts.
                """
        case 28..<40:
            return """
                \(bits) bits of entropy offers basic security. It may be sufficient for low-risk scenarios with strict rate-limiting but is not recommended for important accounts or data. Consider increasing the entropy for stronger protection.
                """
        case 40..<50:
            return """
                \(bits) bits of entropy is moderate. This level is adequate for securing personal accounts or applications that have additional security measures like two-factor authentication or rate-limiting. It strikes a balance between usability and security but could be insufficient for high-value targets.
                """
        case 50..<70:
            return """
                \(bits) bits of entropy is strong. This level is suitable for most personal and professional use cases, providing robust security against brute force attacks. It's a good choice for accounts and data requiring reliable protection.
                """
        case 70..<100:
            return """
                \(bits) bits of entropy is very strong. It offers excellent security and is ideal for sensitive accounts, encryption keys, or long-term protection of valuable data. This level is resistant to brute force attacks, even by determined adversaries.
                """
        case 100...:
            return """
                \(bits) bits of entropy is exceptionally strong and provides an extreme level of security. This is suitable for protecting highly sensitive or critical data, such as cryptographic keys or classified information. However, it may be unnecessary for typical use cases.
                """
        default:
            return """
                Invalid entropy value. Please provide a valid positive integer for the bits of entropy.
                """
    }
}

