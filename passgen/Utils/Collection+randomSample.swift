import Foundation

extension Collection {
    func randomSample(count: Int) -> [Element] {
        let shuffled = self.shuffled()
        if count >= shuffled.count { return Array(shuffled) }
        return Array(shuffled.prefix(count))
    }
}
