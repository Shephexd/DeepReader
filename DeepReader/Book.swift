import Foundation
import SwiftData

@Model
class Book {
    var id: UUID = UUID()
    var title: String
    var contentFileName: String // DB 대신 앱 폴더에 저장된 파일의 이름
    var lastReadDate: Date
    var progress: Double // 읽은 위치 %
    
    // AI 분석 결과 캐싱 (v1.2 추가)
    var foundCharacters: [String]?
    var aiSummary: String?
    var isAICleaned: Bool = false // AI 가독성 정리 완료 여부 (v1.3)
    
    init(title: String, contentFileName: String) {
        self.title = title
        self.contentFileName = contentFileName
        self.lastReadDate = Date()
        self.progress = 0.0
    }
    
    // DB에 저장되지 않는 연산 프로퍼티: 필요할 때만 파일을 읽어옵니다. (메모리 & DB 최적화)
    var content: String {
        let url = URL.documentsDirectory.appendingPathComponent(contentFileName)
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            return "파일 내용을 불러오지 못했습니다."
        }
    }
}
