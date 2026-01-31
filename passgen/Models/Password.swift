import Foundation

struct Password: Identifiable {
    var id = UUID()
    let words: [String]
    let score: Double
}
