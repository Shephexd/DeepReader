import SwiftUI
import SwiftData
import NaturalLanguage
import FirebaseAnalytics

struct BibleContentView: View {
    let bookName: String
    let chapter: Int
    
    @Environment(\.modelContext) private var modelContext
    @State private var verses: [BibleVerse] = []
    @State private var bookInfo: BibleBookInfo?
    
    @StateObject private var ai = AIProcessor()
    @StateObject private var settings = ReaderSettings.shared
    
    @State private var selectedVerse: BibleVerse?
    @State private var englishText = ""
    @State private var showSettings = false
    @State private var isLoading = true
    
    init(bookName: String, chapter: Int) {
        self.bookName = bookName.precomposedStringWithCanonicalMapping
        self.chapter = chapter
    }
    
    var body: some View {
        ZStack {
            ReaderTheme.paperBackground.ignoresSafeArea()
            
            if isLoading {
                VStack {
                    ProgressView()
                    Text("말씀을 불러오는 중...").font(.caption).padding(.top)
                }
            } else if verses.isEmpty {
                emptyView
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(verses) { verse in
                                verseRow(for: verse)
                                    .id(verse.id)
                            }
                            
                            navigationButtons
                        }
                        .padding(.horizontal, 15)
                        .padding(.top, 10)
                    }
                }
            }
        }
        .navigationTitle("\(bookName) \(chapter)장")
        .navigationBarTitleDisplayMode(.inline)
        .id("\(bookName)-\(chapter)")
        .onAppear {
            fetchData()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showSettings = true }) {
                    Image(systemName: "textformat")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            BibleSettingsView(settings: settings)
                .presentationDetents([.medium])
        }
    }
    
    @ViewBuilder
    private func verseRow(for verse: BibleVerse) -> some View {
        let isSelected = selectedVerse?.id == verse.id
        
        VStack(alignment: .leading, spacing: 0) {
            // 본문 행
            HStack(alignment: .top, spacing: 12) {
                Text("\(verse.verse)")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(ReaderTheme.systemBlue.opacity(isSelected ? 1.0 : 0.4))
                    .frame(width: 25, alignment: .trailing)
                    .padding(.top, 10)
                
                Text(BibleFormatter.renderHighlights(content: verse.content, highlightsJson: verse.highlightsJson))
                    .font(.system(size: settings.fontSize, weight: settings.fontType == "Serif" ? .medium : .regular, design: settings.fontType == "Serif" ? .serif : .default))
                    .foregroundColor(ReaderTheme.mainText)
                    .lineSpacing(settings.fontSize * 0.4)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(isSelected ? ReaderTheme.systemBlue.opacity(0.08) : Color.clear)
            .background(verse.isHighlighted && !isSelected ? Color(hex: "FCEE91").opacity(0.3) : Color.clear)
            .cornerRadius(12)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    if isSelected {
                        selectedVerse = nil
                    } else {
                        selectedVerse = verse
                        loadEnglishExpression(for: verse)
                        verse.lastReadDate = Date()
                    }
                }
            }
            
            // 확장 영역 (자연스러운 unfolding 효과)
            if isSelected {
                VStack(alignment: .leading, spacing: 15) {
                    // 1. 액션 버튼
                    HStack(spacing: 15) {
                        ActionButtonSmall(icon: verse.isBookmarked ? "bookmark.fill" : "bookmark", title: "저장", color: verse.isBookmarked ? ReaderTheme.goldAccent : ReaderTheme.secondaryText) {
                            verse.isBookmarked.toggle()
                            try? modelContext.save()
                        }
                        
                        ActionButtonSmall(icon: "highlighter", title: "형광펜", color: !verse.highlightsJson.isEmpty ? ReaderTheme.goldAccent : ReaderTheme.secondaryText) {
                            addHighlight(to: verse, color: "FCEE91")
                        }
                        
                        ActionButtonSmall(icon: "square.and.arrow.up", title: "공유", color: ReaderTheme.systemBlue) {
                            shareVerse(verse)
                        }
                    }
                    .padding(.top, 5)
                    
                    // 2. 영문 성경
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ENGLISH (KJV)")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(ReaderTheme.systemBlue.opacity(0.6))
                        
                        if englishText.isEmpty {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Text(englishText)
                                .font(ReaderTheme.englishFont(size: settings.fontSize * 0.9))
                                .italic()
                                .foregroundColor(ReaderTheme.mainText.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(10)
                    
                    // 3. AI 인사이트 (있을 때만)
                    if !verse.aiInsight.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("AI 묵상 가이드").bold()
                            }
                            .font(.system(size: 11))
                            .foregroundColor(ReaderTheme.aiInsightText)
                            
                            Text(verse.aiInsight)
                                .font(.system(size: 14))
                                .foregroundColor(ReaderTheme.mainText.opacity(0.9))
                                .lineSpacing(4)
                        }
                        .padding(12)
                        .background(ReaderTheme.aiInsightBg)
                        .cornerRadius(10)
                    }
                }
                .padding(.leading, 37)
                .padding(.trailing, 10)
                .padding(.bottom, 20)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: -10)).combined(with: .scale(scale: 0.98, anchor: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
                ))
            }
        }
    }

    private var navigationButtons: some View {
        VStack {
            Divider().padding(.vertical, 30)
            HStack {
                if chapter > 1 {
                    NavigationLink(destination: BibleContentView(bookName: bookName, chapter: chapter - 1)) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("이전 장")
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                Spacer()
                if let info = bookInfo, chapter < info.chapterCount {
                    NavigationLink(destination: BibleContentView(bookName: bookName, chapter: chapter + 1)) {
                        HStack {
                            Text("다음 장")
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(ReaderTheme.systemBlue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
            .foregroundColor(ReaderTheme.mainText)
            .padding(.bottom, 60)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            Text("\(bookName) \(chapter)장 내용을 찾을 수 없습니다.")
                .foregroundColor(.gray)
            Button("다시 시도") { fetchData() }
                .padding()
                .background(ReaderTheme.systemBlue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
    private func fetchData() {
        isLoading = true
        let normalizedName = bookName.precomposedStringWithCanonicalMapping
        let allBooksDescriptor = FetchDescriptor<BibleBookInfo>()
        let allBooks = (try? modelContext.fetch(allBooksDescriptor)) ?? []
        let matchedBook = allBooks.first { $0.name == normalizedName || normalizedName.contains($0.name) || $0.name.contains(normalizedName) }
        let finalBookName = matchedBook?.name ?? normalizedName
        self.bookInfo = matchedBook
        
        let vPredicate = #Predicate<BibleVerse> {
            $0.bookName == finalBookName && $0.chapter == chapter
        }
        let vDescriptor = FetchDescriptor<BibleVerse>(predicate: vPredicate, sortBy: [SortDescriptor(\.verse)])
        
        do {
            self.verses = try modelContext.fetch(vDescriptor)
            isLoading = false
            
            if let info = self.bookInfo {
                Task {
                    info.lastReadDate = Date()
                    info.lastReadChapter = chapter
                    try? modelContext.save()
                    Analytics.logEvent("read_chapter", parameters: ["book_name": info.name, "chapter": chapter])
                }
            }
        } catch {
            isLoading = false
        }
    }
    
    private func loadEnglishExpression(for verse: BibleVerse) {
        self.englishText = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let english = verse.englishContent, !english.isEmpty {
                self.englishText = english
            } else {
                self.englishText = "영문 데이터를 찾을 수 없습니다."
            }
        }
    }

    private func addHighlight(to verse: BibleVerse, color: String) {
        var highlights: [HighlightRange] = []
        if !verse.highlightsJson.isEmpty,
           let data = verse.highlightsJson.data(using: .utf8),
           let existing = try? JSONDecoder().decode([HighlightRange].self, from: data) {
            highlights = existing
        }
        
        let newHighlight = HighlightRange(start: 0, length: verse.content.count, color: color)
        if let index = highlights.firstIndex(where: { $0.color == color }) {
            highlights.remove(at: index)
        } else {
            highlights.append(newHighlight)
        }
        
        if let data = try? JSONEncoder().encode(highlights),
           let json = String(data: data, encoding: .utf8) {
            verse.highlightsJson = json
            try? modelContext.save()
        }
    }

    private func shareVerse(_ verse: BibleVerse) {
        let text = "[\(verse.bookName) \(verse.chapter):\(verse.verse)]\n\(verse.content)\n\n- DeepReader (개역한글)"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            if let popover = av.popoverPresentationController {
                let screenBounds = windowScene.screen.bounds
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: screenBounds.width / 2, y: screenBounds.height / 2, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootVC.present(av, animated: true, completion: nil)
        }
    }
}

// MARK: - Subviews
struct ActionButtonSmall: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12, weight: .bold))
                Text(title).font(.system(size: 12, weight: .bold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(8)
        }
    }
}
