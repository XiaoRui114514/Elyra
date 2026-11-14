// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import SafariServices

struct CreatorProfile: Identifiable {
    let id: String
    let title: String
    let detail: String
    let imageName: String
    let url: URL
    var accent: Color {
        switch id {
        case "douyin": Color(red: 0.0, green: 0.65, blue: 0.70)
        case "xiaohongshu": Color(red: 1.0, green: 0.14, blue: 0.26)
        default: .primary
        }
    }
    static let all: [Self] = [
        .init(id: "github", title: "GitHub", detail: "XiaoRui114514", imageName: "ProfileGitHub", url: URL(string: "https://github.com/XiaoRui114514")!),
        .init(id: "douyin", title: "Douyin", detail: "Videos and updates", imageName: "ProfileDouyin", url: URL(string: "https://v.douyin.com/MKmK56P4roo/")!),
        .init(id: "xiaohongshu", title: "Xiaohongshu", detail: "Posts and updates", imageName: "ProfileXiaohongshu", url: URL(string: "https://xhslink.cn/o/29eRubHJXk9")!)
    ]
}
struct AboutView: View {
    @EnvironmentObject private var localization: LocalizationStore
    @State private var selected: CreatorProfile?
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "circle.hexagongrid").font(.largeTitle).foregroundStyle(.tint).accessibilityHidden(true)
                    Text("Elyra").font(.largeTitle.bold())
                    Text("Device configuration and file tools.").foregroundStyle(.secondary)
                    Text((Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "") + " (" + (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") + ")").font(.caption).foregroundStyle(.secondary)
                }.padding(.vertical, 12)
            }
            Section("Creator profiles") {
                ForEach(CreatorProfile.all) { profile in
                    Button { selected = profile } label: {
                        HStack(spacing: 16) {
                            Image(profile.imageName).resizable().renderingMode(.original).scaledToFit()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous)).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(localization.text(profile.title)).font(.headline).foregroundStyle(.primary)
                                Text(profile.id == "github" ? profile.detail : localization.text(profile.detail)).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 12)
                            Image(systemName: "arrow.up.right").foregroundStyle(profile.accent).accessibilityHidden(true)
                        }.frame(minHeight: 60).padding(.vertical, 5).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .listRowBackground(profile.accent.opacity(0.055))
                        .accessibilityIdentifier("profile." + profile.id)
                }
            }
            Section {
                NavigationLink(value: Screen.openSource) { Label("Open-source licenses", systemImage: "doc.text") }
            }
        }.navigationTitle(localization.text("About Elyra"))
        .sheet(item: $selected) { profile in ProfileBrowser(url: profile.url).ignoresSafeArea() }
    }
}
private struct ProfileBrowser: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
