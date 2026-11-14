// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct LanguageSettingsView: View {
    @EnvironmentObject private var localization: LocalizationStore
    var body: some View {
        List {
            Section {
                languageRow(.system, name: localization.text("Follow System"))
                languageRow(.simplifiedChinese, name: "简体中文")
                languageRow(.english, name: "English")
            } footer: {
                Text("The selected language applies to every Elyra window and is saved for the next launch. File contents and configuration keys keep their original names.")
            }
        }
        .navigationTitle(localization.text("Language"))
    }
    private func languageRow(_ language: AppLanguage, name: String) -> some View {
        Button {
            localization.language = language
        } label: {
            HStack {
                Text(name).foregroundStyle(.primary)
                Spacer(minLength: 12)
                if localization.language == language { Image(systemName: "checkmark").foregroundStyle(.tint) }
            }.frame(minHeight: 44).contentShape(Rectangle())
        }
        .accessibilityIdentifier("language." + language.rawValue)
        .accessibilityAddTraits(localization.language == language ? .isSelected : [])
    }
}
