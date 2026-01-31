import Foundation

public protocol StringScore {
    func getScore<T: StringProtocol>(_ string: T) -> Double
}

extension Character {
    var baseCharacter: Character {
        String(self).applyingTransform(.stripDiacritics, reverse: false)?.first ?? self
    }
}

extension String {
    static let rightIndex = "yuhjnm"
    static let rightMiddle = "ik"
    static let rightRing = "ol"
    static let rightPinky = "p"

    static let leftIndex = "rfvtgb"
    static let leftMiddle = "edc"
    static let leftRing = "wsx"
    static let leftPinky = "qaz"

    static let left = leftIndex + leftMiddle + leftRing + leftPinky
    static let right = rightIndex + rightMiddle + rightRing + rightPinky

    static func hand(forCharacter char: Character) -> String {
        if left.contains(char.baseCharacter) {
            return left
        }
        if right.contains(char.baseCharacter) {
            return right
        }
        return right
    }

    static func finger(forCharacter char: Character) -> String {
        if leftIndex.contains(char.baseCharacter) { return leftIndex }
        if leftMiddle.contains(char.baseCharacter) { return leftMiddle }
        if leftRing.contains(char.baseCharacter) { return leftRing }
        if leftPinky.contains(char.baseCharacter) { return leftPinky }

        if rightIndex.contains(char.baseCharacter) { return rightIndex }
        if rightMiddle.contains(char.baseCharacter) { return rightMiddle }
        if rightRing.contains(char.baseCharacter) { return rightRing }
        if rightPinky.contains(char.baseCharacter) { return rightPinky }
        fatalError()
    }
}

public struct MultiScorer: StringScore {
    let scorers: [StringScore]
    public init(scorers: [StringScore]) {
        self.scorers = scorers
    }
    public func getScore<T: StringProtocol>(_ string: T) -> Double {
        self.scorers.reduce(0) { (partialResult, scorer) -> Double in
            partialResult + (scorer.getScore(string) / Double(scorers.count))
        }
    }
}

public struct SimilarCharsOneApart: StringScore {

    public init() {}

    public func getScore<T: StringProtocol>(_ string: T) -> Double {
        guard string.count > 2 else { return 1 }
        var similars = 0
        var tests = 0
        var prevPrevChar: Character? = nil
        var prevChar: Character? = nil
        for char in string {
            if let pp = prevPrevChar, pp == char {
                similars += 1
            }
            if prevChar != nil {
                tests += 1
            }
            prevPrevChar = prevChar
            prevChar = char
        }
        guard tests > 0 else { return 1 }
        return 1 - (Double(similars) / Double(tests))
    }
}

public struct SwitchFingerFavor: StringScore {

    public init() {}

    public func getScore<T: StringProtocol>(_ string: T) -> Double {
        guard string.isEmpty == false else {
            return 1
        }
        guard string.count > 1 else {
            return 1
        }
        var currentFinger = String.finger(forCharacter: string.first!)
        var switches = 0
        for char in string.dropFirst() {
            let newFinger = String.finger(forCharacter: char)
            if newFinger != currentFinger {
                switches = switches + 1
                currentFinger = newFinger
            }
        }
        return Double(switches) / Double(string.count - 1)
    }
}

public struct SwitchHandFavor: StringScore {

    public init() {}

    public func getScore<T: StringProtocol>(_ string: T) -> Double {
        guard string.isEmpty == false else {
            return 1
        }
        guard string.count > 1 else {
            return 1
        }
        var currentHand = String.hand(forCharacter: string.first!)
        var switches = 0
        for char in string.dropFirst() {

            let newHand = String.hand(forCharacter: char)
            if newHand != currentHand {
                switches = switches + 1
                currentHand = newHand
            }
        }
        return Double(switches) / Double(string.count - 1)
    }
}

public struct PinkyDisfavor: StringScore {

    public init() {}

    public func getScore<T: StringProtocol>(_ string: T) -> Double {
        let r =
            (string.reduce(0) { (partialResult: Double, char: Character) -> Double in
                if String.rightPinky.contains(char) || String.leftPinky.contains(char) {
                    return partialResult + 1
                }
                return partialResult
            }) / Double(string.count)
        return 1 - r
    }
}

public struct DoubleLettersScore: StringScore {

    public init() {}

    public func getScore<T: StringProtocol>(_ string: T) -> Double {
        guard string.isEmpty == false else {
            return 1
        }
        var doubles: Int = 0
        var prevChar: Character? = nil
        for char in string {
            if let prev = prevChar, prev == char {
                doubles += 1
            }
            prevChar = char
        }
        guard doubles <= 1 else {
            return 0
        }
        guard doubles <= 0 else {
            return 0.01
        }
        return 1
    }
}
