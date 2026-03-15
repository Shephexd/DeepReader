import Foundation
import SwiftData

@Model
class BibleVerse {
    var id: UUID = UUID()
    var testament: String // Old, New
    var bookName: String
    var bookIndex: Int // 1-01, 2-01 등 정렬용
    var chapter: Int
    var verse: Int
    var content: String
    var englishContent: String? // KJV 원문 저장용
    
    // AI 인사이트 및 키워드 (정적 DB 연동)
    var aiInsight: String = ""
    var keywords: String = ""
    
    // 핵심 성경 앱 기능
    var isHighlighted: Bool = false
    var isBookmarked: Bool = false
    var highlightColor: String = "" // hex color string
    var highlightsJson: String = "" // JSON string: [{"start": Int, "length": Int, "color": "HEX"}]
    var lastReadDate: Date? // 읽은 날짜 추적용
    
    init(testament: String, bookName: String, bookIndex: Int, chapter: Int, verse: Int, content: String) {
        self.testament = testament
        self.bookName = bookName.precomposedStringWithCanonicalMapping
        self.bookIndex = bookIndex
        self.chapter = chapter
        self.verse = verse
        self.content = content
    }
}

@Model
class BibleBookInfo {
    var id: UUID = UUID()
    var name: String
    var testament: String
    var bookIndex: Int
    var chapterCount: Int
    
    // 읽기 히스토리 추적용
    var lastReadDate: Date?
    var lastReadChapter: Int?
    
    init(name: String, testament: String, bookIndex: Int, chapterCount: Int) {
        self.name = name
        self.testament = testament
        self.bookIndex = bookIndex
        self.chapterCount = chapterCount
    }
}
