import SwiftUI
import SwiftData
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("🚀 Firebase Successfully Initialized")
        return true
    }
}

@main
struct DeepReaderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var loaderViewModel = BibleLoaderViewModel()
    @State private var showMainView = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showMainView {
                    LibraryView()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // SwiftData 컨테이너 접근을 위해 modelContext 전달
                    SplashScreenRoot(loader: loaderViewModel, showMainView: $showMainView)
                }
            }
            .animation(.easeInOut(duration: 0.6), value: showMainView)
        }
        .modelContainer(for: [Book.self, BibleVerse.self, BibleBookInfo.self])
    }
}

// ModelContext 접근을 위한 래퍼 뷰
struct SplashScreenRoot: View {
    @ObservedObject var loader: BibleLoaderViewModel
    @Binding var showMainView: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [BibleBookInfo]
    
    var body: some View {
        SplashScreenView(loader: loader, modelContext: modelContext)
            .onChange(of: loader.isImporting) { oldValue, newValue in
                // 로딩이 끝났고(false), 데이터가 존재하면 메인 화면으로 이동
                if oldValue == true && newValue == false && !books.isEmpty {
                    withAnimation {
                        showMainView = true
                    }
                }
            }
            .onAppear {
                // 이미 데이터가 로드되어 있는 경우 바로 메인으로 이동
                if !loader.isImporting && !books.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { // 로고 감상 시간
                        withAnimation {
                            showMainView = true
                        }
                    }
                }
            }
    }
}
