import SwiftUI
import Combine

class ReaderSettings: ObservableObject {
    @AppStorage("fontSize") var fontSize: Double = UIDevice.current.userInterfaceIdiom == .pad ? 24.0 : 18.0
    @AppStorage("fontType") var fontType: String = "Serif" // 기본값을 Serif로 변경
    @AppStorage("lineSpacing") var lineSpacing: Double = 1.5
    @AppStorage("paragraphSpacing") var paragraphSpacing: Double = 12.0
    @AppStorage("targetLanguage") var targetLanguage: String = "en-US"
    @AppStorage("useModernTerms") var useModernTerms: Bool = false // 개역한글을 위해 기본값 false
    
    // 아이패드 여부에 따른 폰트 범위
    var minFontSize: Double { UIDevice.current.userInterfaceIdiom == .pad ? 18.0 : 14.0 }
    var maxFontSize: Double { UIDevice.current.userInterfaceIdiom == .pad ? 45.0 : 32.0 }
    
    static let shared = ReaderSettings()
    
    private init() {}
}
