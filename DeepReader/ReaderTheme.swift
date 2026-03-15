import SwiftUI

struct ReaderTheme {
    // 1. 프리미엄 배경 색상
    static var paperBackground: Color {
        Color("PaperBackground")
    }
    
    static var sepiaBackground: Color {
        Color(hex: "F4F1EA")
    }
    
    // 2. 텍스트 색상
    static var mainText: Color {
        Color("MainText")
    }
    
    static var secondaryText: Color {
        Color("SecondaryText")
    }
    
    static var sepiaText: Color {
        Color(hex: "4A443A")
    }
    
    // 3. 포인트 색상
    static let systemBlue = Color(hex: "345A7D") // 네이비 계열
    static let goldAccent = Color(hex: "D4AF37")
    static let highlightYellow = Color(hex: "FCEE91") // 형광펜
    
    static let dialogueGray = Color(hex: "8E8E93")
    
    // AI 인사이트 개선 색상
    static let aiInsightBg = Color.orange.opacity(0.1)
    static let aiInsightText = Color.orange
    
    // 폰트 설정
    static func englishFont(size: CGFloat) -> Font {
        return .custom("Georgia", size: size) // 세리프 계열 영문 폰트
    }
}

// Color Hex Extension
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
