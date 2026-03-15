import SwiftUI
import UIKit

class NovelProcessor {
    func parse(text: String) -> NSAttributedString {
        let settings = ReaderSettings.shared
        let fullRange = NSRange(location: 0, length: text.utf16.count)
        let attributedString = NSMutableAttributedString(string: text)
        
        // 1. 프로 조판 스타일 (전자책 표준 레이아웃)
        let paragraphStyle = NSMutableParagraphStyle()
        
        // 자연스러운 정렬 (이미지처럼 단어가 벌어지는 것을 방지)
        paragraphStyle.alignment = .natural 
        
        // 단어 중간이 끊기는 현상 방지 (한국어 최적화)
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineBreakStrategy = [.pushOut, .hangulWordPriority]
        
        // 행간 조절: 사용자 설정 반영
        paragraphStyle.lineHeightMultiple = CGFloat(settings.lineSpacing)
        
        // 문단 간격 및 첫 줄 들여쓰기
        paragraphStyle.paragraphSpacing = CGFloat(settings.paragraphSpacing)
        paragraphStyle.firstLineHeadIndent = 15 // 소설다운 느낌을 위해 15로 설정
        
        // 폰트 설정
        let font: UIFont
        switch settings.fontType {
        case "Serif":
            font = UIFont(name: "AppleSDGothicNeo-Regular", size: CGFloat(settings.fontSize)) ?? .systemFont(ofSize: CGFloat(settings.fontSize))
        case "Mono":
            font = UIFont.monospacedSystemFont(ofSize: CGFloat(settings.fontSize), weight: .regular)
        default:
            font = UIFont.systemFont(ofSize: CGFloat(settings.fontSize), weight: .regular)
        }
        
        attributedString.addAttributes([
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor(ReaderTheme.sepiaText),
            .kern: 0.5 // 자간 미세 조정
        ], range: fullRange)
        
        // 2. [시스템 메시지] 스타일링 (게임 판타지 특화)
        let statusRegex = try! NSRegularExpression(pattern: "\\[.*?\\]", options: [])
        statusRegex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            if let range = match?.range {
                attributedString.addAttributes([
                    .font: UIFont.systemFont(ofSize: 19, weight: .bold),
                    .foregroundColor: UIColor(ReaderTheme.systemBlue)
                ], range: range)
            }
        }
        
        // 3. "대화체" 스타일링 (가독성 포인트)
        let dialogueRegex = try! NSRegularExpression(pattern: "\".*?\"", options: [])
        dialogueRegex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            if let range = match?.range {
                attributedString.addAttributes([
                    .font: UIFont.systemFont(ofSize: 19, weight: .medium),
                    .foregroundColor: UIColor.black // 대화는 조금 더 진하게
                ], range: range)
            }
        }
        
        return attributedString
    }
}
