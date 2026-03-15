import SwiftUI
import SwiftData

struct SplashScreenView: View {
    @ObservedObject var loader: BibleLoaderViewModel
    var modelContext: ModelContext
    @State private var opacity = 0.0
    @State private var scale = 0.8
    
    var body: some View {
        ZStack {
            ReaderTheme.paperBackground.ignoresSafeArea()
            
            VStack(spacing: 25) {
                Spacer()
                
                // 앱 로고 (텍스트 형태 또는 아이콘)
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(ReaderTheme.systemBlue)
                        .frame(width: 120, height: 120)
                        .shadow(color: ReaderTheme.systemBlue.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Text("D")
                        .font(.system(size: 60, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                VStack(spacing: 10) {
                    Text("DeepReader")
                        .font(.system(size: 32, weight: .black, design: .serif))
                        .foregroundColor(ReaderTheme.systemBlue)
                    
                    Text("시대를 초월한 말씀의 깊이")
                        .font(.subheadline)
                        .foregroundColor(ReaderTheme.secondaryText)
                        .tracking(2)
                }
                .opacity(opacity)
                
                Spacer()
                
                // 로딩 프로그레스
                if loader.isImporting {
                    VStack(spacing: 15) {
                        ProgressView(value: loader.progress)
                            .progressViewStyle(.linear)
                            .frame(width: 200)
                            .tint(ReaderTheme.goldAccent)
                        
                        Text(loader.statusMessage)
                            .font(.caption)
                            .foregroundColor(ReaderTheme.secondaryText)
                    }
                    .transition(.opacity)
                }
                
                Spacer()
                
                Text("개역한글 & KJV")
                    .font(.caption2)
                    .foregroundColor(ReaderTheme.secondaryText.opacity(0.5))
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                self.opacity = 1.0
                self.scale = 1.0
            }
            
            // 데이터 로드가 필요한지 체크 후 시작
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                loader.loadIfNeeded(context: modelContext)
            }
        }
    }
}
