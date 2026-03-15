import Foundation
import NaturalLanguage

func cleanupText(text: String) -> String {
    var cleaned = text.replacingOccurrences(of: "([가-힣])\\s*\\n+\\s*([가-힣])", with: "$1$2", options: .regularExpression)
    cleaned = cleaned.replacingOccurrences(of: "\\n\\s*\\n+", with: "[[PARA]]", options: .regularExpression)
    cleaned = cleaned.replacingOccurrences(of: "\\n", with: " ")
    let rawParagraphs = cleaned.components(separatedBy: "[[PARA]]")
    var finalResult = ""
    for rawPara in rawParagraphs {
        let flatPara = rawPara.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
        if flatPara.isEmpty { continue }
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = flatPara
        var cleanedPara = ""
        tokenizer.enumerateTokens(in: flatPara.startIndex..<flatPara.endIndex) { range, _ in
            let sentence = String(flatPara[range]).trimmingCharacters(in: .whitespaces)
            if cleanedPara.isEmpty { cleanedPara = sentence } else {
                let specialPatterns = ["^\\s*\\[", "^\\s*\"", "^\\s*「", "^\\s*-"]
                let isSpecial = specialPatterns.contains { pattern in sentence.range(of: pattern, options: .regularExpression) != nil }
                if isSpecial { cleanedPara += "\n" + sentence } else { cleanedPara += " " + sentence }
            }
            return true
        }
        if finalResult.isEmpty { finalResult = cleanedPara } else { finalResult += "\n" + cleanedPara }
    }
    return finalResult.replacingOccurrences(of: "([^\\n])\\s*\\[", with: "$1\n[", options: .regularExpression)
}

func summarize(text: String) -> String {
    let tagger = NLTagger(tagSchemes: [.lexicalClass])
    tagger.string = text
    var keywordCounts: [String: Int] = [:]
    let range = text.startIndex..<text.index(text.startIndex, offsetBy: min(20000, text.count))
    tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: [.omitWhitespace, .omitPunctuation]) { tag, range in
        if tag == .noun {
            let word = String(text[range])
            if word.count >= 2 { keywordCounts[word, default: 0] += 1 }
        }
        return true
    }
    let tokenizer = NLTokenizer(unit: .sentence)
    tokenizer.string = text
    var sentenceScores: [(sentence: String, score: Int, index: Int)] = []
    var index = 0
    tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
        let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        if sentence.count < 30 || sentence.count > 200 { return true }
        var score = 0
        for (keyword, count) in keywordCounts { if sentence.contains(keyword) { score += 5 + (count / 2) } }
        if sentence.hasPrefix("\"") || sentence.hasPrefix("「") { score += 3 }
        if index < 15 { score += 10 }
        sentenceScores.append((sentence, score, index))
        index += 1
        return true
    }
    let topSentences = sentenceScores.sorted(by: { $0.score > $1.score }).prefix(5).sorted(by: { $0.index < $1.index }).map { $0.sentence }
    return topSentences.joined(separator: "\n\n")
}

let basePath = "/Users/shephexd/.gemini/tmp/deepreader/test_novel/"
let fileManager = FileManager.default
let files = (try? fileManager.contentsOfDirectory(atPath: basePath)) ?? []

print("🚀 COMPREHENSIVE TEST")

for target in ["[01]", "[10]", "[20]"] {
    if let actualName = files.first(where: { $0.contains(target) }) {
        let path = basePath + actualName
        
        // iconv를 이용해 UTF-8로 변환 후 읽기
        let task = Process()
        task.launchPath = "/usr/bin/iconv"
        task.arguments = ["-f", "cp949", "-t", "utf-8", path]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let content = String(data: data, encoding: .utf8) {
            print("\n--- \(target)권 ---")
            let cleaned = cleanupText(text: content)
            print("✅ Cleaned Sample: \(cleaned.prefix(150))...")
            print("\n✅ AI Summary:")
            print(summarize(text: content))
        } else {
            print("❌ Failed: \(actualName)")
        }
    } else {
        print("❌ Could not find: \(target)")
    }
}
