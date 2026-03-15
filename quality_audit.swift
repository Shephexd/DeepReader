import Foundation
import NaturalLanguage

// AI 로직 복사 (테스트용)
struct QualityTester {
    static func analyzeVolume(title: String, content: String) {
        print("\n[INSPECTION] Volume: \(title)")
        print("- Size: \(Double(content.count) / 1024.0 / 1024.0) MB")
        
        let start = Date()
        
        // 1. 인물 추출 테스트
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = content
        var nameCandidates: [String: Int] = [:]
        let range = content.startIndex..<content.index(content.startIndex, offsetBy: min(20000, content.count))
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: [.omitPunctuation, .omitWhitespace, .joinNames]) { tag, range in
            if tag == .personalName { nameCandidates[String(content[range]), default: 0] += 10 }
            return true
        }
        
        let topNames = nameCandidates.sorted(by: { $0.value > $1.value }).prefix(5).map { $0.key }
        print("- Key Characters: \(topNames.joined(separator: ", "))")
        
        // 2. 요약 퀄리티 테스트 (문장 길이 및 분포)
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = content
        var count = 0
        tokenizer.enumerateTokens(in: content.startIndex..<content.endIndex) { _, _ in
            count += 1
            return true
        }
        print("- Total Sentences: \(count)")
        
        let duration = Date().timeIntervalSince(start)
        print("- Processing Time: \(String(format: "%.2f", duration))s")
        
        if duration > 2.0 {
            print("⚠️ WARNING: Processing is slow for this volume.")
        } else {
            print("✨ PERFORMANCE: Optimal")
        }
    }
}

// 전체 파일 순회
let basePath = "/Users/shephexd/.gemini/tmp/deepreader/test_novel/"
let fileManager = FileManager.default
let files = (try? fileManager.contentsOfDirectory(atPath: basePath))?.sorted() ?? []

print("📚 DEEPREADER TOTAL QUALITY AUDIT")
print("Target: 달빛조각사 Full Dataset")

for fileName in files where fileName.contains("[") && fileName.contains(".txt") {
    let path = basePath + fileName
    let task = Process()
    task.launchPath = "/usr/bin/iconv"
    task.arguments = ["-f", "cp949", "-t", "utf-8", path]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let content = String(data: data, encoding: .utf8) {
        QualityTester.analyzeVolume(title: fileName, content: content)
    }
}
