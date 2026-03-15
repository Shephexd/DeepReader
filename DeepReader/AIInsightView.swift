import SwiftUI

struct AIInsightView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var ai: AIProcessor
    let book: Book
    
    var body: some View {
        NavigationView {
            ZStack {
                ReaderTheme.sepiaBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        statisticsSection
                        characterSection
                        summarySection
                        translationSection
                        remasterSection
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("AI 인사이트")
            .onAppear {
                loadInitialData()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if !ai.isProcessing { ai.summarize(text: book.content) }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") { dismiss() }
                }
            }
            .onReceive(ai.$isProcessing) { isProcessing in
                if !isProcessing && !ai.summary.isEmpty {
                    saveAnalysisResult()
                }
            }
        }
    }
    
    // --- Subviews ---
    
    @ViewBuilder
    private var statisticsSection: some View {
        HStack(spacing: 20) {
            StatCard(title: "분량", value: "\(book.content.count)자", icon: "doc.text")
            StatCard(title: "읽기 속도", value: "평균", icon: "speedometer")
            StatCard(title: "상태", value: book.isAICleaned ? "AI 최적화" : "원본", icon: "sparkles")
        }
        .padding(.top, 10)
    }
    
    @ViewBuilder
    private var characterSection: some View {
        if !ai.foundCharacters.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("주요 인물 (\(ai.foundCharacters.count)명)")
                    .font(.headline)
                    .foregroundColor(ReaderTheme.systemBlue)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ai.foundCharacters, id: \.self) { char in
                            Text(char)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(ReaderTheme.systemBlue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "sparkles")
                Text("AI 핵심 요약")
            }
            .font(.headline)
            .foregroundColor(ReaderTheme.systemBlue)
            
            Text(ai.summary.isEmpty ? "분석 중..." : ai.summary)
                .font(.subheadline)
                .lineSpacing(5)
                .padding()
                .background(Color.white.opacity(0.5))
                .cornerRadius(10)
        }
    }
    
    @ViewBuilder
    private var translationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "globe")
                Text("AI 스마트 번역 (\(ReaderSettings.shared.targetLanguage))")
            }
            .font(.headline)
            .foregroundColor(.orange)
            
            if ai.translatedText.isEmpty {
                Button(action: {
                    ai.translate(text: ai.summary, targetLanguage: ReaderSettings.shared.targetLanguage)
                }) {
                    HStack {
                        if ai.isProcessing && ai.translatedText.isEmpty {
                            ProgressView().padding(.trailing, 5)
                        }
                        Text("요약본 번역하기")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.orange)
                    .bold()
                }
                .disabled(ai.isProcessing || ai.summary.isEmpty)
            } else {
                Text(ai.translatedText)
                    .font(.subheadline)
                    .italic()
                    .padding()
                    .background(Color.orange.opacity(0.05))
                    .cornerRadius(10)
                    .foregroundColor(.black.opacity(0.8))
            }
        }
    }
    
    @ViewBuilder
    private var remasterSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "wand.and.stars")
                Text("AI 텍스트 리마스터")
            }
            .font(.headline)
            .foregroundColor(ReaderTheme.systemBlue)
            
            Text("지저분한 줄바꿈과 문장을 AI가 깔끔하게 정리해 줍니다.")
                .font(.caption)
                .foregroundColor(ReaderTheme.dialogueGray)
            
            Button(action: {
                ai.cleanupText(from: book.content) { _ in }
            }) {
                HStack {
                    if ai.isProcessing && ai.cleanedText.isEmpty {
                        ProgressView().padding(.trailing, 5)
                    }
                    Text(ai.cleanedText.isEmpty ? "지금 바로 정리하기" : "정리 완료! (읽기 화면에 적용됨)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(ReaderTheme.systemBlue.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(ReaderTheme.systemBlue)
                .bold()
            }
            .disabled(ai.isProcessing)
        }
    }
    
    // --- Actions ---
    
    private func loadInitialData() {
        if !ai.isProcessing {
            if let saved = DatabaseManager.shared.getAnalysis(id: book.id.uuidString) {
                ai.summary = saved.summary
                ai.foundCharacters = saved.characters
            } else if let cachedSummary = book.aiSummary {
                ai.summary = cachedSummary
                ai.foundCharacters = book.foundCharacters ?? []
            } else {
                ai.summarize(text: book.content)
            }
        }
    }
    
    private func saveAnalysisResult() {
        book.foundCharacters = ai.foundCharacters
        book.aiSummary = ai.summary
        DatabaseManager.shared.storeAnalysis(
            id: book.id.uuidString,
            title: book.title,
            content: book.content,
            characters: ai.foundCharacters,
            summary: ai.summary
        )
    }
}

struct StatCard: View {
    let title: String; let value: String; let icon: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.headline).foregroundColor(ReaderTheme.systemBlue)
            Text(title).font(.caption2).foregroundColor(.gray)
            Text(value).font(.system(size: 14, weight: .bold)).foregroundColor(ReaderTheme.sepiaText)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.white.opacity(0.5)).cornerRadius(12)
    }
}
