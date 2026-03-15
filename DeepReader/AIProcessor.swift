import Foundation
import NaturalLanguage
import Combine

class AIProcessor: ObservableObject {
    @Published var foundCharacters: [String] = []
    @Published var summary: String = ""
    @Published var translatedText: String = ""
    @Published var isProcessing: Bool = false
    @Published var cleanedText: String = ""
    @Published var translationInsight: String = ""
    @Published var remasteredVerses: [UUID: String] = [:]

    // AI 스마트 클린 (문장 종결 기반 딥 클리닝)
    func cleanupText(from text: String, completion: @escaping (String) -> Void) {
        self.isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 1. 단어 중간 잘림 및 파편화된 줄바꿈 정리
            var cleaned = text.replacingOccurrences(of: "([가-힣])\\s*\\n+\\s*([가-힣])", with: "$1$2", options: .regularExpression)
            
            // 2. 의미 있는 문단 구분자 보호 (엔터 2개 이상)
            cleaned = cleaned.replacingOccurrences(of: "\\n\\s*\\n+", with: "[[PARA]]", options: .regularExpression)
            
            // 3. 나머지 단일 줄바꿈은 공백으로 치환
            cleaned = cleaned.replacingOccurrences(of: "\\n", with: " ")
            
            let rawParagraphs = cleaned.components(separatedBy: "[[PARA]]")
            var finalResult = ""
            
            for rawPara in rawParagraphs {
                let flatPara = rawPara.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                                      .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if flatPara.isEmpty { continue }
                
                // 문단 내 문장 분리
                let tokenizer = NLTokenizer(unit: .sentence)
                tokenizer.string = flatPara
                
                var cleanedPara = ""
                tokenizer.enumerateTokens(in: flatPara.startIndex..<flatPara.endIndex) { range, _ in
                    let sentence = String(flatPara[range]).trimmingCharacters(in: .whitespaces)
                    
                    if cleanedPara.isEmpty {
                        cleanedPara = sentence
                    } else {
                        // 특수 문구 감지
                        let specialPatterns = ["^\\s*\\[", "^\\s*\"", "^\\s*「", "^\\s*-"]
                        let isSpecial = specialPatterns.contains { pattern in
                            sentence.range(of: pattern, options: .regularExpression) != nil
                        }
                        
                        if isSpecial {
                            cleanedPara += "\n" + sentence
                        } else {
                            cleanedPara += " " + sentence
                        }
                    }
                    return true
                }
                
                if finalResult.isEmpty {
                    finalResult = cleanedPara
                } else {
                    finalResult += "\n" + cleanedPara
                }
            }
            
            let refined = finalResult.replacingOccurrences(of: "([^\\n])\\s*\\[", with: "$1\n[", options: .regularExpression)
            
            DispatchQueue.main.async {
                self.cleanedText = refined
                self.isProcessing = false
                completion(refined)
            }
        }
    }

    // 사전 구축된 인사이트 데이터베이스 (포맷 개선)
    private let staticInsights: [String: String] = [
        "창세기 1:1": """
            ✨ [번역 인사이트]
            
            히브리어 원어 '베레쉬트(Bereshit)'는 단순히 시간적인 '태초'를 넘어, 모든 것의 '근본'이자 '원리'라는 의미를 내포하고 있습니다. 
            
            🔹 영문 KJV의 'In the beginning'은 이를 시간적 출발점으로 담백하게 번역하여 창조의 시작을 선포합니다.
            """,
        "창세기 1:2": """
            🔍 [단어 연구]
            
            '혼돈(Tohu)'과 '공허(Bohu)'는 형태도 없고 채워지지도 않은 절대적 무(無)의 상태를 뜻합니다. 
            
            🔹 하나님의 창조는 이 무질서(Chaos)에 질서(Cosmos)를 부여하고 생명으로 채우는 위대한 과정입니다.
            """,
        "요한복음 1:1": """
            📖 [신학적 배경]
            
            '말씀(Logos)'은 헬라 철학에서 우주의 이성이자 원리를 뜻하는 깊은 철학적 단어였습니다. 
            
            🔹 요한은 이 단어를 빌려와 예수님이 곧 우주의 근본 원리이자 창조주이심을 선포했습니다.
            """,
        "로마서 8:28": """
            🕊️ [번역 인사이트]
            
            '합력하여 선을 이룬다'는 것은 모든 일이 내 뜻대로 된다는 뜻이 아닙니다. 
            
            🔹 하나님께서 모든 상황(고난 포함)을 정교하게 엮어 결국 그분의 선하신 목적을 완성하신다는 신뢰의 고백입니다.
            """
    ]

    // 정적 데이터 기반 인사이트 조회 + 전 구절 동적 생성 (하이브리드)
    func explainTranslationGap(bookName: String, chapter: Int, verse: Int, korean: String, english: String) {
        self.isProcessing = true
        self.translationInsight = ""
        
        let key = "\(bookName) \(chapter):\(verse)"
        
        DispatchQueue.global(qos: .userInitiated).async {
            var finalInsight = ""
            
            // 1. 사전 정의된 고품질 정적 데이터 우선 확인
            if let insight = self.staticInsights[key] {
                finalInsight = insight
            } else {
                // 2. 정적 데이터가 없으면 본문을 분석하여 전 구절 동적 인사이트 생성
                let tagger = NLTagger(tagSchemes: [.lexicalClass])
                tagger.string = korean
                
                var nouns: [String] = []
                tagger.enumerateTags(in: korean.startIndex..<korean.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, range in
                    if tag == .noun { nouns.append(String(korean[range])) }
                    return true
                }
                
                // 테마 매핑 사전
                let themes: [String: (title: String, desc: String)] = [
                    "사랑": ("❤️ [사랑의 속성]", "성경에서 말하는 '사랑'은 단순한 감정이 아닌 의지적 헌신(Agape)을 의미하는 경우가 많습니다. 영문 번역본에 따라 Love 또는 Charity로 번역되며 뉘앙스가 달라집니다."),
                    "구원": ("✝️ [구원의 뉘앙스]", "한국어 '구원'은 건져냄의 의미가 강한 반면, 영어 'Salvation'은 온전한 상태로의 회복과 치유의 의미를 함께 내포하고 있습니다."),
                    "믿음": ("🙏 [믿음의 본질]", "성경적 '믿음(Faith/Pistis)'은 지적 동의를 넘어선 신뢰와 충성을 의미합니다. 이 구절에서 강조되는 믿음의 행동적 측면을 영어 원문과 함께 묵상해 보세요."),
                    "은혜": ("🎁 [은혜의 의미]", "'은혜(Grace)'는 받을 자격 없는 자에게 주어지는 호의입니다. 한국어 번역은 이 단어의 깊은 신학적 무게를 담아내고 있습니다."),
                    "말씀": ("📖 [말씀의 권위]", "'말씀(Word)'은 단순한 소리가 아닌, 창조의 능력이자 인격적인 진리(Logos)를 가리킵니다."),
                    "영광": ("✨ [영광의 무게]", "한국어 '영광'은 빛나는 상태를 뜻하지만, 원어의 뉘앙스는 '무거움' 즉, 하나님의 본질적 가치와 위엄을 나타냅니다."),
                    "거룩": ("🕊️ [거룩의 구별]", "'거룩(Holy)'은 단순히 깨끗한 상태가 아니라, 세속적인 것과 완전히 '구별된' 하나님의 속성을 의미합니다."),
                    "생명": ("🌱 [생명의 차원]", "여기서 '생명(Life)'은 단순한 생물학적 생존(Bios)이 아닌, 하나님과 연결된 영원하고 참된 생명(Zoe)을 의미할 수 있습니다."),
                    "빛": ("💡 [빛의 상징]", "성경에서 '빛(Light)'은 진리, 생명, 그리고 하나님의 임재를 상징하는 가장 강력한 메타포 중 하나입니다."),
                    "어둠": ("🌑 [어둠의 상징]", "어둠(Darkness)은 단순히 빛이 없는 상태를 넘어, 혼돈, 죄악, 무지의 영적 상태를 표현합니다."),
                    "성령": ("🔥 [성령의 임재]", "'성령(Holy Spirit)'은 때론 바람(Pneuma)이나 숨결로 묘사되며, 이 구절에서는 생명을 불어넣고 인도하시는 역동성을 보여줍니다.")
                ]
                
                var matchedTheme: (String, String)?
                for noun in nouns {
                    if let theme = themes[noun] {
                        matchedTheme = theme
                        break
                    }
                }
                
                // 동적 인사이트 조립
                if let theme = matchedTheme {
                    finalInsight = """
                    \(theme.0)
                    
                    \(theme.1)
                    
                    🔹 영어 KJV 원문과 대조해 보시면, 한국어 개역한글의 이 단어가 문맥에서 어떻게 기능하는지 더욱 선명하게 다가옵니다.
                    """
                } else if korean.count > 80 {
                    finalInsight = """
                    📜 [구조와 문체 분석]
                    
                    이 구절은 한국어 특유의 긴 호흡(만연체)을 사용하여 서사적인 깊이와 상황의 장엄함을 전달하고 있습니다.
                    
                    🔹 반면 영어 KJV는 조금 더 간결하고 직관적인 구문 구조를 가지는 경우가 많습니다. 두 언어의 표현 방식을 교차해서 읽어보세요.
                    """
                } else if let firstNoun = nouns.first {
                    finalInsight = """
                    🔍 [핵심 키워드 묵상: \(firstNoun)]
                    
                    이 절에서 눈여겨볼 핵심 단어 중 하나는 '\(firstNoun)'입니다. 
                    
                    🔹 한국어 개역한글은 문어체적 위엄을, 영문 KJV는 고전적인 운율을 중시합니다. 두 언어에서 표현이 어떻게 상호보완되는지 대조하며 깊은 의미를 묵상해 보세요.
                    """
                } else {
                    finalInsight = """
                    💡 [비교 묵상 포인트]
                    
                    한국어 개역한글 성경은 전통적인 위엄과 경건함을 강조하는 어투를 사용합니다. 
                    
                    🔹 KJV의 영어 원문과 나란히 읽어보시면, 번역 과정에서 나타나는 미세한 어감의 차이와 새로운 묵상 포인트를 발견하실 수 있습니다.
                    """
                }
            }
            
            DispatchQueue.main.async {
                self.translationInsight = finalInsight
                self.isProcessing = false
            }
        }
    }


    // (기타 요약, 추출 로직 유지...)
    func extractCharacters(from text: String, updateProcessingState: Bool = true, completion: (([String]) -> Void)? = nil) {
        if updateProcessingState { isProcessing = true }
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        var names: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: [.joinNames]) { tag, range in
            if tag == .personalName { names.append(String(text[range])) }
            return true
        }
        let result = Array(Set(names)).prefix(10).map { String($0) }
        DispatchQueue.main.async {
            self.foundCharacters = result
            if updateProcessingState { self.isProcessing = false }
            completion?(result)
        }
    }

    func summarize(text: String) {
        isProcessing = true
        DispatchQueue.global(qos: .userInitiated).async {
            let sentences = text.components(separatedBy: ".")
            let result = sentences.prefix(3).joined(separator: ".\n")
            DispatchQueue.main.async {
                self.summary = result.isEmpty ? "내용이 짧아 요약이 어렵습니다." : result
                self.isProcessing = false
            }
        }
    }

    // AI 스마트 번역 기능
    func translate(text: String, targetLanguage: String) {
        self.isProcessing = true
        
        // 실제 API 호출을 시뮬레이션
        DispatchQueue.global(qos: .userInitiated).async {
            Thread.sleep(forTimeInterval: 1.0)
            
            let translated = "[AI 번역 결과 (\(targetLanguage))]\n" + text
            
            DispatchQueue.main.async {
                self.translatedText = translated
                self.isProcessing = false
            }
        }
    }
}
