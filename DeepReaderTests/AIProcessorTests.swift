import XCTest
@testable import DeepReader

final class AIProcessorTests: XCTestCase {
    var ai: AIProcessor!
    
    override func setUp() {
        super.setUp()
        ai = AIProcessor()
    }
    
    // 1. 클리닝 성능 테스트
    func testTextCleanup() {
        let dirtyText = "죽 \n 여버리고 싶었다. 식사 \n 를 했다."
        let expectation = XCTestExpectation(description: "Cleanup")
        
        ai.cleanupText(from: dirtyText) { cleaned in
            XCTAssertFalse(cleaned.contains(" \n "))
            XCTAssertTrue(cleaned.contains("죽여버리고"))
            XCTAssertTrue(cleaned.contains("식사를"))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    // 2. 인물 추출 성능 테스트
    func testCharacterExtraction() {
        let text = "이현은 길을 걸었다. 이현은 할머니를 생각했다. 이혜연이 나타났다."
        ai.extractCharacters(from: text)
        
        XCTAssertTrue(ai.foundCharacters.contains("이현"))
        XCTAssertTrue(ai.foundCharacters.contains("이혜연"))
    }
}
