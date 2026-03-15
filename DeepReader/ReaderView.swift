import SwiftUI

struct ReaderView: View {
    @Environment(\.modelContext) private var modelContext
    let book: Book
    let processor = NovelProcessor()
    
    @StateObject private var ai = AIProcessor()
    @StateObject private var settings = ReaderSettings.shared
    @State private var showAIInsight = false
    @State private var showSettings = false
    
    // 현재 화면에 보여지는 텍스트 (AI 정리 결과가 반영됨)
    @State private var displayedContent: String = ""
    
    // 설정이 변경될 때마다 뷰를 강제 갱신하기 위한 ID
    @State private var updateID = UUID()
    
    var body: some View {
        ZStack {
            ReaderTheme.sepiaBackground.ignoresSafeArea()
            
            if displayedContent.isEmpty {
                LoadingOverlay(progress: 0.5, message: "AI가 텍스트를 정리 중입니다...")
            } else {
                VStack(spacing: 0) {
                    AttributedText(attributedString: processor.parse(text: displayedContent))
                        .id(updateID)
                    
                    // 하단 읽기 상태 바
                    HStack {
                        Text("\(Int(book.progress * 100))%")
                            .font(.caption2)
                            .foregroundColor(ReaderTheme.sepiaText.opacity(0.7))
                        
                        ProgressView(value: book.progress)
                            .tint(ReaderTheme.systemBlue.opacity(0.5))
                            .scaleEffect(x: 1, y: 0.5)
                        
                        Text(book.title)
                            .font(.caption2)
                            .foregroundColor(ReaderTheme.sepiaText.opacity(0.7))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 10)
                    .background(ReaderTheme.sepiaBackground)
                }
                .ignoresSafeArea(edges: .bottom)
            }
            
            // AI 플로팅 버튼
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showAIInsight = true }) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(ReaderTheme.systemBlue).shadow(radius: 5))
                    }
                    .padding(25)
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear { 
            book.lastReadDate = Date()

            // 이미 정리가 끝난 책이라면 즉시 표시
            if book.isAICleaned {
                displayedContent = book.content
            } else {
                // 아직 정리가 안 된 책만 강제 재정리 실행
                ai.cleanupText(from: book.content) { cleaned in
                    displayedContent = cleaned

                    // 영구 저장 및 상태 업데이트
                    let url = URL.documentsDirectory.appendingPathComponent(book.contentFileName)
                    try? cleaned.write(to: url, atomically: true, encoding: .utf8)

                    book.isAICleaned = true
                }
            }
        }

        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showSettings = true }) {
                    Image(systemName: "textformat")
                        .foregroundColor(ReaderTheme.sepiaText)
                }
            }
        }
        .sheet(isPresented: $showAIInsight) {
            AIInsightView(ai: ai, book: book)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings, updateID: $updateID)
                .presentationDetents([.medium, .large]) // 높이 확장
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings: ReaderSettings
    @Binding var updateID: UUID
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("글꼴 설정")) {
                    HStack {
                        Text("크기")
                        Slider(value: $settings.fontSize, in: 14...30, step: 1)
                            .onChange(of: settings.fontSize) { updateID = UUID() }
                        Text("\(Int(settings.fontSize))")
                    }
                    
                    Picker("글꼴", selection: $settings.fontType) {
                        Text("시스템").tag("System")
                        Text("본명조").tag("Serif")
                        Text("고딕").tag("Mono")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: settings.fontType) { updateID = UUID() }
                }
                
                Section(header: Text("간격 설정")) {
                    HStack {
                        Text("행간")
                        Slider(value: $settings.lineSpacing, in: 1.0...2.0, step: 0.1)
                            .onChange(of: settings.lineSpacing) { updateID = UUID() }
                    }
                }
                
                Section(header: Text("번역 설정")) {
                    Picker("대상 언어", selection: $settings.targetLanguage) {
                        Text("영어").tag("en-US")
                        Text("일본어").tag("ja-JP")
                        Text("중국어").tag("zh-CN")
                        Text("프랑스어").tag("fr-FR")
                    }
                }
            }
            .navigationTitle("보기 설정")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AttributedText: UIViewRepresentable {
    let attributedString: NSAttributedString
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = true 
        
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 25, bottom: 50, right: 25)
        textView.textContainer.lineFragmentPadding = 0
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedString
    }
}

struct LoadingOverlay: View {
    let progress: Double
    let message: String
    var body: some View {
        VStack(spacing: 15) {
            ProgressView(value: progress).progressViewStyle(.linear).frame(width: 200)
            Text(message).font(.caption).foregroundColor(.gray)
        }
        .padding(30).background(Color.white.opacity(0.9)).cornerRadius(20).shadow(radius: 10)
    }
}
