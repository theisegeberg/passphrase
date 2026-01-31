import Foundation

struct PasswordGenerator {
    let words = wordlist.split(separator: "\n")

    func generate(wordCount:Int) -> [Password] {
        
        let multiScorer = MultiScorer(scorers: [
            SwitchHandFavor(),
            SwitchFingerFavor(),
            SimilarCharsOneApart(),
        ])
        
        let scoredPasswords: [Password] = (0..<500)
            .map { _ in
                let words = words.randomSample(count: Int(wordCount)).map { String($0) }
                
                let score = multiScorer.getScore(words.joined())
                return Password(words: words, score: score)
            }
            .sorted { a, b in
                a.score < b.score
            }
     
        return scoredPasswords
    }
    
}
