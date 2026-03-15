import Foundation
import SwiftData
import SQLite3
import Combine

class BibleLoaderViewModel: ObservableObject {
    @Published var isImporting = false
    @Published var progress: Double = 0
    @Published var statusMessage: String = ""

    @MainActor
    func clearAndLoad(container: ModelContainer) {
        isImporting = true
        statusMessage = "데이터베이스 재구성 중..."
        Task.detached {
            let context = ModelContext(container)
            try? context.delete(model: BibleVerse.self)
            try? context.delete(model: BibleBookInfo.self)
            try? context.save()
            await self.startLoading(container: container)
        }
    }

    @MainActor
    func loadIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<BibleBookInfo>()
        if (try? context.fetchCount(descriptor)) ?? 0 > 0 { return }
        isImporting = true
        Task { await self.startLoading(container: context.container) }
    }

    private func startLoading(container: ModelContainer) async {
        // 마스터 DB 파일 경로 확인
        guard let masterDbUrl = Bundle.main.url(forResource: "BibleMaster", withExtension: "sqlite", subdirectory: "Bible") ?? 
                               Bundle.main.url(forResource: "BibleMaster", withExtension: "sqlite") else {
            await MainActor.run { 
                self.statusMessage = "마스터 DB 파일을 찾을 수 없습니다."
                self.isImporting = false 
            }
            return
        }

        var db: OpaquePointer?
        if sqlite3_open(masterDbUrl.path, &db) != SQLITE_OK {
            await MainActor.run { self.isImporting = false }
            return
        }

        await MainActor.run { self.statusMessage = "통합 데이터 적재 중..." }
        
        let backgroundContext = ModelContext(container)
        backgroundContext.autosaveEnabled = false

        // 1. 책 정보 로드 (book_info 테이블)
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, "SELECT book_index, name_ko, testament, chapter_count FROM book_info", -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let index = Int(sqlite3_column_int(stmt, 0))
                let name = String(cString: sqlite3_column_text(stmt, 1))
                let testament = String(cString: sqlite3_column_text(stmt, 2))
                let chapters = Int(sqlite3_column_int(stmt, 3))
                
                let info = BibleBookInfo(name: name, testament: testament, bookIndex: index, chapterCount: chapters)
                backgroundContext.insert(info)
            }
        }
        sqlite3_finalize(stmt)

        // 2. 말씀 데이터 로드 (verses 테이블)
        if sqlite3_prepare_v2(db, "SELECT testament, book_name_ko, chapter, verse, content_ko, content_en, ai_insight, keywords FROM verses", -1, &stmt, nil) == SQLITE_OK {
            var count = 0
            while sqlite3_step(stmt) == SQLITE_ROW {
                let testament = String(cString: sqlite3_column_text(stmt, 0))
                let bookName = String(cString: sqlite3_column_text(stmt, 1))
                let chapter = Int(sqlite3_column_int(stmt, 2))
                let verse = Int(sqlite3_column_int(stmt, 3))
                let contentKo = String(cString: sqlite3_column_text(stmt, 4))
                let contentEn = String(cString: sqlite3_column_text(stmt, 5))
                let insight = String(cString: sqlite3_column_text(stmt, 6))
                let keywords = String(cString: sqlite3_column_text(stmt, 7))
                
                let bibleVerse = BibleVerse(testament: testament, bookName: bookName, bookIndex: 0, chapter: chapter, verse: verse, content: contentKo)
                bibleVerse.englishContent = contentEn
                bibleVerse.aiInsight = insight
                bibleVerse.keywords = keywords
                backgroundContext.insert(bibleVerse)
                
                // 검색용 SQLite 인덱싱 동시 진행
                DatabaseManager.shared.indexBibleVerse(id: bibleVerse.id, testament: testament, bookName: bookName, chapter: chapter, verse: verse, content: contentKo, englishContent: contentEn)
                
                count += 1
                if count % 1000 == 0 {
                    let p = Double(count) / 31102.0
                    await MainActor.run { 
                        self.progress = p
                        self.statusMessage = "말씀 최적화 중... (\(Int(p*100))%)"
                    }
                }
            }
            try? backgroundContext.save()
        }
        sqlite3_finalize(stmt)
        sqlite3_close(db)

        await MainActor.run {
            self.isImporting = false
            self.statusMessage = "통합 완료!"
        }
    }
}
