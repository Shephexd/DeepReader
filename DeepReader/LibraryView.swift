import SwiftUI
import SwiftData
import NaturalLanguage

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BibleBookInfo.bookIndex) private var bibleBooks: [BibleBookInfo]
    
    @StateObject private var loaderViewModel = BibleLoaderViewModel()
    @State private var selectedTestament = "Old"
    @State private var showSearch = false
    @State private var showDatabaseManagement = false
    
    var filteredBooks: [BibleBookInfo] {
        bibleBooks.filter { $0.testament == selectedTestament }
    }
    
    var body: some View {
        TabView {
            // 탭 1: 성경 서재
            ZStack {
                ReaderTheme.paperBackground.ignoresSafeArea()
                
                NavigationStack {
                    MainBibleListView(
                        filteredBooks: filteredBooks, 
                        selectedTestament: $selectedTestament,
                        recentBook: bibleBooks.filter { $0.lastReadDate != nil }.sorted { $0.lastReadDate! > $1.lastReadDate! }.first
                    )
                    .navigationTitle("개역한글 성경")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showDatabaseManagement = true }) {
                                Image(systemName: "server.rack").foregroundColor(ReaderTheme.systemBlue)
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            if !bibleBooks.isEmpty {
                                Button(action: { showSearch = true }) {
                                    Image(systemName: "magnifyingglass").foregroundColor(ReaderTheme.systemBlue)
                                }
                            }
                        }
                    }
                }
                
                if loaderViewModel.isImporting {
                    loadingOverlay
                }
            }
            .sheet(isPresented: $showSearch) { 
                NavigationStack {
                    BibleSearchView() 
                }
            }
            .sheet(isPresented: $showDatabaseManagement) {
                DatabaseManagementView(loaderViewModel: loaderViewModel, modelContext: modelContext)
                    .presentationDetents([.medium])
            }
            .tabItem {
                Label("서재", systemImage: "book.fill")
            }
            
            // 탭 2: 읽기 달력
            ReadingCalendarView()
                .tabItem {
                    Label("달력", systemImage: "calendar")
                }
            
            // 탭 3: 저장한 말씀
            MyVersesView()
                .tabItem {
                    Label("저장됨", systemImage: "bookmark.fill")
                }
        }
        .tint(ReaderTheme.systemBlue)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 20) {
                if loaderViewModel.progress < 1.0 && !loaderViewModel.statusMessage.contains("오류") && !loaderViewModel.statusMessage.contains("없습니다") {
                    ProgressView(value: loaderViewModel.progress)
                        .progressViewStyle(.linear)
                        .frame(width: 200)
                }
                Text(loaderViewModel.statusMessage)
                    .foregroundColor(.white)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(30)
            .background(Color.black.opacity(0.7))
            .cornerRadius(20)
        }
    }
}

// MARK: - Subviews

struct MainBibleListView: View {
    let filteredBooks: [BibleBookInfo]
    @Binding var selectedTestament: String
    var recentBook: BibleBookInfo?
    
    var body: some View {
        VStack(spacing: 0) {
            if let recent = recentBook, let lastChapter = recent.lastReadChapter {
                VStack(alignment: .leading, spacing: 8) {
                    Text("이어 읽기")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(ReaderTheme.systemBlue)
                    
                    NavigationLink(destination: BibleContentView(bookName: recent.name, chapter: lastChapter)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(recent.name) \(lastChapter)장")
                                    .font(.headline)
                                    .foregroundColor(ReaderTheme.mainText)
                                Text("마지막으로 읽은 성경 구절로 바로 이동합니다.")
                                    .font(.caption)
                                    .foregroundColor(ReaderTheme.secondaryText)
                            }
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                                .foregroundColor(ReaderTheme.goldAccent)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(15)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(ReaderTheme.paperBackground)
            }
            
            Picker("성경 구분", selection: $selectedTestament) {
                Text("구약성경 (Old)").tag("Old")
                Text("신약성경 (New)").tag("New")
            }
            .pickerStyle(.segmented).padding().background(ReaderTheme.paperBackground)
            
            List {
                Section(header: Text(selectedTestament == "Old" ? "Old Testament - 총 39권" : "New Testament - 총 27권")
                    .font(.caption).foregroundColor(ReaderTheme.systemBlue)) {
                    ForEach(filteredBooks) { book in
                        NavigationLink(destination: BibleChapterView(book: book)) {
                            HStack(spacing: 15) {
                                ZStack {
                                    Circle().fill(selectedTestament == "Old" ? ReaderTheme.goldAccent.opacity(0.15) : ReaderTheme.systemBlue.opacity(0.1))
                                    Text("\(book.bookIndex % 100)").font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(selectedTestament == "Old" ? ReaderTheme.goldAccent : ReaderTheme.systemBlue)
                                }.frame(width: 30, height: 30)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(book.name).font(.system(size: 18, weight: .bold)).foregroundColor(ReaderTheme.mainText)
                                    Text("\(book.chapterCount) Chapters").font(.system(size: 12)).foregroundColor(ReaderTheme.secondaryText)
                                }
                                Spacer()
                            }.padding(.vertical, 4)
                        }.listRowBackground(Color.white.opacity(0.1))
                    }
                }
            }.listStyle(.insetGrouped)
        }
    }
}

struct ReadingCalendarView: View {
    @Query(filter: #Predicate<BibleVerse> { $0.lastReadDate != nil }, sort: \BibleVerse.lastReadDate, order: .reverse) private var readVerses: [BibleVerse]
    @State private var selectedDate: Date = Date()
    private var calendar: Calendar { Calendar.current }
    
    private var activityDates: Set<Date> {
        let dates = readVerses.compactMap { $0.lastReadDate }.map { calendar.startOfDay(for: $0) }
        return Set(dates)
    }
    
    private var filteredVerses: [BibleVerse] {
        readVerses.filter { 
            if let date = $0.lastReadDate {
                return calendar.isDate(date, inSameDayAs: selectedDate)
            }
            return false
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ReaderTheme.paperBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    DatePicker("읽기 날짜 선택", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .tint(ReaderTheme.goldAccent)
                        .padding()
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(20)
                        .padding()
                    
                    HStack {
                        Circle().fill(ReaderTheme.goldAccent).frame(width: 8, height: 8)
                        Text("기록이 있는 날짜").font(.caption2).foregroundColor(ReaderTheme.secondaryText)
                        Spacer()
                        Text("\(activityDates.count)일간의 여정").font(.caption).bold().foregroundColor(ReaderTheme.systemBlue)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 10)
                    
                    Divider()
                    
                    if filteredVerses.isEmpty {
                        Spacer()
                        Text("읽은 말씀이 없습니다.").foregroundColor(ReaderTheme.secondaryText)
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredVerses) { verse in
                                NavigationLink(destination: BibleContentView(bookName: verse.bookName, chapter: verse.chapter)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(verse.bookName) \(verse.chapter):\(verse.verse)").font(.caption).bold().foregroundColor(ReaderTheme.systemBlue)
                                        Text(verse.content).font(.subheadline).lineLimit(1).foregroundColor(ReaderTheme.mainText)
                                    }
                                }
                            }
                        }.scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("성경 읽기 여정")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MyVersesView: View {
    @Query(filter: #Predicate<BibleVerse> { $0.isBookmarked || !$0.highlightsJson.isEmpty }, sort: \BibleVerse.bookIndex) private var savedVerses: [BibleVerse]
    @ObservedObject private var settings = ReaderSettings.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                ReaderTheme.paperBackground.ignoresSafeArea()
                if savedVerses.isEmpty {
                    VStack {
                        Image(systemName: "bookmark.slash").font(.system(size: 60)).foregroundColor(ReaderTheme.secondaryText.opacity(0.3))
                        Text("저장된 말씀이 없습니다.").foregroundColor(ReaderTheme.secondaryText).padding(.top, 10)
                    }
                } else {
                    List {
                        ForEach(savedVerses) { verse in
                            NavigationLink(destination: BibleContentView(bookName: verse.bookName, chapter: verse.chapter)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("\(verse.bookName) \(verse.chapter):\(verse.verse)").font(.caption).bold().foregroundColor(ReaderTheme.systemBlue)
                                        Spacer()
                                        if !verse.highlightsJson.isEmpty { Image(systemName: "highlighter").foregroundColor(ReaderTheme.goldAccent) }
                                        if verse.isBookmarked { Image(systemName: "bookmark.fill").foregroundColor(ReaderTheme.goldAccent) }
                                    }
                                    Text(verse.content).font(.subheadline).lineLimit(2).foregroundColor(ReaderTheme.mainText)
                                }
                            }
                        }
                    }.scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("저장한 말씀")
        }
    }
}

struct BibleChapterView: View {
    let book: BibleBookInfo
    let columns = [GridItem(.adaptive(minimum: UIDevice.current.userInterfaceIdiom == .pad ? 100 : 65), spacing: 15)]
    
    var body: some View {
        ZStack {
            ReaderTheme.paperBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.testament == "Old" ? "구약성경" : "신약성경").font(.caption).fontWeight(.bold).foregroundColor(ReaderTheme.systemBlue)
                            Text(book.name).font(.largeTitle).fontWeight(.black).foregroundColor(ReaderTheme.mainText)
                        }
                        Spacer()
                        Text("총 \(book.chapterCount)장").font(.subheadline).foregroundColor(ReaderTheme.secondaryText).padding(.horizontal, 12).padding(.vertical, 6).background(Color.secondary.opacity(0.1)).cornerRadius(20)
                    }.padding(.horizontal).padding(.top, 10)
                    Divider().padding(.horizontal)
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(1...book.chapterCount, id: \.self) { chapter in
                            NavigationLink(destination: BibleContentView(bookName: book.name.precomposedStringWithCanonicalMapping, chapter: chapter)) {
                                VStack {
                                    Text("\(chapter)").font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 28 : 20, weight: .bold, design: .rounded))
                                    Text("CHAPTER").font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 10 : 8, weight: .medium)).opacity(0.5)
                                }.frame(maxWidth: .infinity).frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 100 : 70)
                                .background(RoundedRectangle(cornerRadius: 15).fill(Color.secondary.opacity(0.1)))
                                .foregroundColor(ReaderTheme.mainText)
                            }
                        }
                    }.padding()
                }
            }
        }
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SearchBar: View {
    @Binding var text: String
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.gray)
            TextField("단어 또는 구절 입력...", text: $text)
            if !text.isEmpty {
                Button(action: { text = "" }) { Image(systemName: "xmark.circle.fill").foregroundColor(.gray) }
            }
        }.padding(10).background(Color.white.opacity(0.6)).cornerRadius(10)
    }
}

struct DatabaseManagementView: View {
    @ObservedObject var loaderViewModel: BibleLoaderViewModel
    var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 25) {
            Text("데이터베이스 관리").font(.headline).padding(.top)
            VStack(alignment: .leading, spacing: 15) {
                Text("성경 데이터가 올바르게 표시되지 않는 경우 초기화할 수 있습니다.").font(.caption).foregroundColor(ReaderTheme.secondaryText)
                Button(action: {
                    dismiss()
                    loaderViewModel.clearAndLoad(container: modelContext.container)
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("데이터 초기화 및 전체 재구성")
                    }
                    .frame(maxWidth: .infinity).padding().background(Color.red.opacity(0.1)).foregroundColor(.red).cornerRadius(12)
                }
            }
            .padding().background(Color.secondary.opacity(0.05)).cornerRadius(15)
            Spacer()
        }
        .padding()
    }
}
