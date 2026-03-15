import Foundation
import NaturalLanguage

func summarize(text: String) -> String {
    let tagger = NLTagger(tagSchemes: [.lexicalClass])
    tagger.string = text
    
    var keywordCounts: [String: Int] = [:]
    let range = text.startIndex..<text.index(text.startIndex, offsetBy: min(20000, text.count))
    
    tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: [.omitWhitespace, .omitPunctuation]) { tag, range in
        if tag == .noun {
            let word = String(text[range])
            if word.count >= 2 {
                keywordCounts[word, default: 0] += 1
            }
        }
        return true
    }
    
    print("DEBUG: Detected Keywords: \(keywordCounts.sorted(by: { $0.value > $1.value }).prefix(10))")
    
    let tokenizer = NLTokenizer(unit: .sentence)
    tokenizer.string = text
    
    var sentenceScores: [(sentence: String, score: Int, index: Int)] = []
    var index = 0
    
    tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
        let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        if sentence.count < 30 || sentence.count > 150 { return true }
        
        var score = 0
        for (keyword, count) in keywordCounts {
            if sentence.contains(keyword) {
                score += 5 + (count / 2)
            }
        }
        
        if sentence.hasPrefix("\"") || sentence.hasPrefix("「") {
            score += 3
        }
        
        // 도입부 20문장에 가중치
        if index < 20 { score += 10 }
        
        sentenceScores.append((sentence, score, index))
        index += 1
        return true
    }
    
    let topSentences = sentenceScores
        .sorted(by: { $0.score > $1.score })
        .prefix(5)
        .sorted(by: { $0.index < $1.index })
        .map { $0.sentence }
    
    return topSentences.joined(separator: "\n\n")
}

let filePath = "/Users/shephexd/Github/DeepReader/sample_full.txt"
if let rawString = try? String(contentsOfFile: filePath, encoding: .utf8) {
    print("--- GENERATING SUMMARY FROM sample_full.txt ---")
    let summary = summarize(text: rawString)
    print("\n--- SUMMARY RESULT ---")
    print(summary)
} else {
    print("Failed to read sample_full.txt")
}
