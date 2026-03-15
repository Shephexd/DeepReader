import SwiftUI

struct BibleSettingsView: View {
    @ObservedObject var settings: ReaderSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("글꼴 설정")) {
                    HStack {
                        Text("크기")
                        Slider(value: $settings.fontSize, in: 14...35, step: 1)
                        Text("\(Int(settings.fontSize))")
                    }
                    
                    Picker("글꼴", selection: $settings.fontType) {
                        Text("시스템").tag("System")
                        Text("본명조").tag("Serif")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("간격 설정")) {
                    HStack {
                        Text("행간")
                        Slider(value: $settings.lineSpacing, in: 1.0...2.0, step: 0.1)
                    }
                }
                
                Section(header: Text("연구 지원")) {
                    Toggle("쉬운 현대어 교정", isOn: $settings.useModernTerms)
                        .tint(ReaderTheme.systemBlue)
                    Text("개역한글의 '떡', '감람나무' 등을 '빵', '올리브나무' 등으로 실시간 교정하여 보여줍니다.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("보기 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") { dismiss() }
                }
            }
        }
    }
}
