import Foundation
import SQLite3

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    
    private init() { setupDatabase() }
    deinit { sqlite3_close(db) }
    
    private func setupDatabase() {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let dbPath = documentsURL.appendingPathComponent("DeepReader.sqlite").path
        
        if sqlite3_open(dbPath, &db) != SQLITE_OK { return }
        
        // FTS5 테이블 생성 (englishContent 포함)
        execute(query: "CREATE VIRTUAL TABLE IF NOT EXISTS BibleSearch USING fts5(id UNINDEXED, testament, bookName, chapter UNINDEXED, verse UNINDEXED, content, englishContent, tokenize = 'unicode61');")
        execute(query: "CREATE TABLE IF NOT EXISTS AnalysisResult (id TEXT PRIMARY KEY, title TEXT, content TEXT, characters TEXT, summary TEXT, createdAt DATETIME DEFAULT CURRENT_TIMESTAMP);")
    }
    
    private func execute(query: String) {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    func indexBibleVerse(id: UUID, testament: String, bookName: String, chapter: Int, verse: Int, content: String, englishContent: String?) {
        let query = "INSERT OR REPLACE INTO BibleSearch (id, testament, bookName, chapter, verse, content, englishContent) VALUES (?, ?, ?, ?, ?, ?, ?);"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, id.uuidString, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, testament, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, bookName, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 4, Int32(chapter))
            sqlite3_bind_int(statement, 5, Int32(verse))
            sqlite3_bind_text(statement, 6, content, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 7, (englishContent ?? ""), -1, SQLITE_TRANSIENT)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    func searchBible(text: String) -> [SearchResult] {
        var results: [SearchResult] = []
        // 영문과 한글 모두 검색 가능하도록 MATCH 쿼리 사용
        let query = "SELECT id, testament, bookName, chapter, verse, content, englishContent FROM BibleSearch WHERE BibleSearch MATCH ? ORDER BY rank LIMIT 100;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            let terms = text.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces)
            let matchQuery = terms.map { "\($0)*" }.joined(separator: " AND ")
            sqlite3_bind_text(statement, 1, matchQuery, -1, SQLITE_TRANSIENT)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                results.append(SearchResult(
                    id: String(cString: sqlite3_column_text(statement, 0)),
                    testament: String(cString: sqlite3_column_text(statement, 1)),
                    bookName: String(cString: sqlite3_column_text(statement, 2)),
                    chapter: Int(sqlite3_column_int(statement, 3)),
                    verse: Int(sqlite3_column_int(statement, 4)),
                    content: String(cString: sqlite3_column_text(statement, 5)),
                    englishContent: String(cString: sqlite3_column_text(statement, 6))
                ))
            }
        }
        sqlite3_finalize(statement)
        return results
    }
    
    // ... (Analysis 관련 메서드 생략)
    func storeAnalysis(id: String, title: String, content: String, characters: [String], summary: String) {
        let query = "INSERT OR REPLACE INTO AnalysisResult (id, title, content, characters, summary) VALUES (?, ?, ?, ?, ?);"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, title, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, content, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 4, characters.joined(separator: ","), -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 5, summary, -1, SQLITE_TRANSIENT)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    func getAnalysis(id: String) -> Analysis? {
        let query = "SELECT title, content, characters, summary FROM AnalysisResult WHERE id = ?;"
        var statement: OpaquePointer?
        var result: Analysis? = nil
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, id, -1, SQLITE_TRANSIENT)
            if sqlite3_step(statement) == SQLITE_ROW {
                result = Analysis(id: id, title: String(cString: sqlite3_column_text(statement, 0)), content: String(cString: sqlite3_column_text(statement, 1)), characters: String(cString: sqlite3_column_text(statement, 2)).components(separatedBy: ","), summary: String(cString: sqlite3_column_text(statement, 3)))
            }
        }
        sqlite3_finalize(statement)
        return result
    }
}

struct SearchResult: Identifiable {
    let id: String
    let testament: String
    let bookName: String
    let chapter: Int
    let verse: Int
    let content: String
    let englishContent: String // 영문 필드 추가
}

struct Analysis {
    let id: String; let title: String; let content: String; let characters: [String]; let summary: String
}
