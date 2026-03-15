import SwiftUI

struct BibleFormatter {
    static func format(_ text: String, useModernTerms: Bool = false) -> String {
        var formatted = text
        if useModernTerms {
            formatted = formatted.replacingOccurrences(of: "가라사대", with: "이르시되")
            formatted = formatted.replacingOccurrences(of: "가라사니", with: "이르시니")
            formatted = formatted.replacingOccurrences(of: "그리하면", with: "그렇게 하면")
        }
        return formatted
    }
    
    static func renderHighlights(content: String, highlightsJson: String) -> AttributedString {
        var attributed = AttributedString(content)
        
        guard !highlightsJson.isEmpty,
              let data = highlightsJson.data(using: .utf8),
              let highlights = try? JSONDecoder().decode([HighlightRange].self, from: data) else {
            return attributed
        }
        
        for highlight in highlights {
            let startIdx = content.index(content.startIndex, offsetBy: max(0, min(highlight.start, content.count)))
            let endIdx = content.index(content.startIndex, offsetBy: max(0, min(highlight.start + highlight.length, content.count)))
            
            if let start = AttributedString.Index(startIdx, within: attributed),
               let end = AttributedString.Index(endIdx, within: attributed) {
                let range = start..<end
                attributed[range].backgroundColor = Color(hex: highlight.color).opacity(0.4)
            }
        }
        
        return attributed
    }
    
    static func highlightSearchTerm(content: String, term: String) -> AttributedString {
        var attributed = AttributedString(content)
        guard !term.isEmpty else { return attributed }
        
        let lowerContent = content.lowercased()
        let lowerTerm = term.lowercased()
        
        var searchRange = lowerContent.startIndex..<lowerContent.endIndex
        while let range = lowerContent.range(of: lowerTerm, options: [], range: searchRange) {
            if let start = AttributedString.Index(range.lowerBound, within: attributed),
               let end = AttributedString.Index(range.upperBound, within: attributed) {
                let attributedRange = start..<end
                attributed[attributedRange].backgroundColor = Color.yellow.opacity(0.4)
                attributed[attributedRange].inlinePresentationIntent = .stronglyEmphasized
            }
            searchRange = range.upperBound..<lowerContent.endIndex
        }
        
        return attributed
    }
}

struct HighlightRange: Codable {
    let start: Int
    let length: Int
    let color: String
}
