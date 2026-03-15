import SwiftUI
import SwiftData
import FirebaseAnalytics

struct BibleSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    
    var body: some View {
        ZStack {
            ReaderTheme.paperBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                SearchBar(text: $searchText)
                    .padding()
                    .onChange(of: searchText) { oldValue, newValue in
                        if newValue.isEmpty {
                            searchResults = []
                        } else {
                            searchResults = DatabaseManager.shared.searchBible(text: newValue)

                            // 검색 이벤트 기록
                            if newValue.count >= 2 {
                                Analytics.logEvent("search_bible", parameters: [
                                    "search_term": newValue,
                                    "result_count": searchResults.count
                                ])
                            }

                        }
                    }
                if searchResults.isEmpty {
                    Spacer()
                    if searchText.isEmpty {
                        Image(systemName: "text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("성경 구절을 검색해보세요").foregroundColor(.gray).padding(.top, 10)
                    } else {
                        Text("검색 결과가 없습니다.").foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    List {
                        Text("총 \(searchResults.count)개의 결과")
                            .font(.caption).foregroundColor(.gray).listRowBackground(Color.clear)
                        ForEach(searchResults) { verse in
                            NavigationLink(destination: BibleContentView(bookName: verse.bookName, chapter: verse.chapter)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("\(verse.bookName) \(verse.chapter):\(verse.verse)")
                                            .font(.caption).bold().foregroundColor(ReaderTheme.systemBlue)
                                        Spacer()
                                        Text(verse.testament).font(.system(size: 8)).padding(4).background(Color.gray.opacity(0.1)).cornerRadius(4)
                                    }

                                    Text(BibleFormatter.highlightSearchTerm(content: verse.content, term: searchText))
                                        .font(.subheadline).foregroundColor(ReaderTheme.mainText)

                                    if !verse.englishContent.isEmpty {
                                        Text(verse.englishContent)
                                            .font(.system(size: 12, design: .serif)).italic()
                                            .foregroundColor(.gray)
                                            .lineLimit(2)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.white.opacity(0.5))
                        }

                    }
                    .listStyle(.plain)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("성경 검색")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("닫기") { dismiss() }
            }
        }
    }
}
