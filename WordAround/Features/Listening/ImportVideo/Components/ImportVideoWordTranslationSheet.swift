import SwiftUI

struct ImportVideoWordTranslationSheet: View {
    @ObservedObject var viewModel: ImportVideoSessionViewModel

    @State private var mode: Mode = .translation
    @State private var newSetTitle = ""
    @State private var newSetDescription = ""
    @State private var newSetColor: SetColor = .green

    private enum Mode { case translation, setPicker, createSet }

    private let accent = ListeningTheme.importVideoAccent
    private let accentDark = ListeningTheme.importVideoDark

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Capsule().fill(AppColors.mutedText.opacity(0.3))
                    .frame(width: 40, height: 5).frame(maxWidth: .infinity)
                switch mode {
                case .translation: translationCard
                case .setPicker:   setPickerCard
                case .createSet:   createSetCard
                }
            }
            .padding(20)
            .frame(maxWidth: Layout.convContentMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .background(AppColors.appBackground.ignoresSafeArea())
        .tint(accentDark)
    }

    private var translationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("From").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(AppColors.mutedText)
                    Text(viewModel.setup.language.title).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(accentDark)
                    Image(systemName: "arrow.right").font(.system(size: 12, weight: .bold)).foregroundColor(AppColors.mutedText)
                }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Translate to").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundColor(AppColors.mutedText)
                        Text(viewModel.translationTarget.title).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundColor(accentDark)
                    }
                    Spacer()
                    targetLanguageMenu
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous).fill(accent.opacity(0.06)))
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.selectedWord ?? "")
                    .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(accentDark)
                if viewModel.isTranslating {
                    ListeningLoadingRow(message: "Translating…", accent: accent)
                } else if let result = viewModel.wordTranslation {
                    Text(result.translatedText).font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundColor(accent)
                } else if let error = viewModel.wordTranslationError {
                    Text(error).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(Color(red: 0.95, green: 0.42, blue: 0.40))
                }
                if let context = viewModel.selectedWordContext {
                    Text(context).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(AppColors.textSecondary).padding(.top, 2)
                }
            }

            if let savedName = viewModel.savedToSetName {
                successBanner("Saved to \(savedName)")
            }

            ListeningPrimaryButton(title: "Add to Set", icon: "plus.rectangle.on.folder.fill", accent: accent, accentDark: accentDark) {
                viewModel.loadSetsIfNeeded()
                mode = .setPicker
            }
            .disabled(viewModel.wordTranslation == nil)
            .opacity(viewModel.wordTranslation == nil ? 0.5 : 1)
        }
    }

    private var targetLanguageMenu: some View {
        Menu {
            ForEach(GrammarLanguage.allCases.filter { $0 != viewModel.setup.language }) { language in
                Button(language.title) { viewModel.changeTranslationTarget(language) }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.translationTarget.shortTitle).font(.system(size: 13, weight: .bold, design: .rounded))
                Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(accentDark)
            .padding(.horizontal, 12).frame(height: 34)
            .background(accent.opacity(0.12)).clipShape(Capsule())
        }
    }

    private var setPickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                backButton { mode = .translation }
                Text("Choose a set").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(accentDark)
                Spacer()
                Button {
                    newSetTitle = ""; newSetDescription = ""; mode = .createSet
                } label: {
                    Image(systemName: "plus").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                        .frame(width: 34, height: 34).background(accent).clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if let savedName = viewModel.savedToSetName { successBanner("Saved to \(savedName)") }
            if let error = viewModel.setSaveError {
                Text(error).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(Color(red: 0.95, green: 0.42, blue: 0.40))
            }

            if viewModel.isLoadingSets {
                ListeningLoadingRow(message: "Loading your sets…", accent: accent)
            } else if viewModel.availableSets.isEmpty {
                Text("You have no sets yet. Tap + to create one.")
                    .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(AppColors.textSecondary)
            } else {
                ForEach(viewModel.availableSets) { set in
                    Button { viewModel.addTranslationToSet(setID: set.id) } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(hex: set.colorHex) ?? accent).frame(width: 30, height: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(set.title).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(accentDark)
                                Text("\(set.cards.count) cards").font(.system(size: 12, weight: .medium, design: .rounded)).foregroundColor(AppColors.mutedText)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill").foregroundColor(accent)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous).fill(Color.white.opacity(0.9)))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSavingToSet)
                }
            }
        }
    }

    private var createSetCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                backButton { mode = .setPicker }
                Text("New set").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(accentDark)
                Spacer()
            }
            field("Set name") { TextField("e.g. Video words", text: $newSetTitle) }
            field("Description") { TextField("Optional", text: $newSetDescription) }

            Text("Color").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(AppColors.textSecondary)
            HStack(spacing: 10) {
                ForEach(SetColor.allCases) { color in
                    Circle().fill(color.color).frame(width: 32, height: 32)
                        .overlay(Circle().stroke(accentDark, lineWidth: newSetColor == color ? 3 : 0))
                        .onTapGesture { newSetColor = color }
                }
            }

            if let error = viewModel.setSaveError {
                Text(error).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(Color(red: 0.95, green: 0.42, blue: 0.40))
            }

            ListeningPrimaryButton(
                title: viewModel.isSavingToSet ? "Saving…" : "Create & Add Word",
                icon: "checkmark.circle.fill", accent: accent, accentDark: accentDark
            ) {
                viewModel.createSetAndAdd(title: newSetTitle, description: newSetDescription, color: newSetColor)
            }
            .disabled(viewModel.isSavingToSet || newSetTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .onChange(of: viewModel.savedToSetName) { _, newValue in
            if newValue != nil { mode = .setPicker }
        }
    }

    private func field<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(AppColors.textSecondary)
            content()
                .font(.system(size: 15, weight: .medium, design: .rounded)).foregroundColor(accentDark)
                .padding(.horizontal, 12).frame(height: 44)
                .background(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous).fill(accent.opacity(0.06)))
        }
    }

    private func backButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "chevron.left").font(.system(size: 14, weight: .bold)).foregroundColor(accentDark)
                .frame(width: 32, height: 32).background(accent.opacity(0.10)).clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func successBanner(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill").foregroundColor(accent)
            Text(text).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(accentDark)
        }
        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous).fill(accent.opacity(0.10)))
    }
}
