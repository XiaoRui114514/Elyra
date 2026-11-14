// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import SafariServices

struct CreatorProfile: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let url: URL
    static let all: [Self] = [
        .init(id: "github", title: "GitHub", detail: "XiaoRui114514", symbol: "chevron.left.forwardslash.chevron.right", url: URL(string: "https://github.com/XiaoRui114514")!),
        .init(id: "douyin", title: "Douyin", detail: "Videos and updates", symbol: "play.rectangle", url: URL(string: "https://v.douyin.com/MKmK56P4roo/")!),
        .init(id: "xiaohongshu", title: "Xiaohongshu", detail: "Posts and updates", symbol: "book.closed", url: URL(string: "https://xhslink.cn/o/29eRubHJXk9")!)
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
                            Image(systemName: profile.symbol).font(.title2).frame(width: 36).foregroundStyle(.tint).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(localization.text(profile.title)).font(.headline).foregroundStyle(.primary)
                                Text(profile.id == "github" ? profile.detail : localization.text(profile.detail)).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 12)
                            Image(systemName: "arrow.up.right").foregroundStyle(.secondary).accessibilityHidden(true)
                        }.frame(minHeight: 60).padding(.vertical, 5).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityIdentifier("profile." + profile.id)
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
