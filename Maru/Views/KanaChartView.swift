import SwiftUI

// MARK: - KanaChartView

struct KanaChartView: View {
    @StateObject private var viewModel = KanaChartViewModel()
    @State private var showDetail = false

    private let columns = [
        GridItem(.adaptive(minimum: 70, maximum: 90), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Hiragana/Katakana picker
                Picker("Kana Type", selection: $viewModel.selectedType) {
                    ForEach(AppConstants.KanaType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .onChange(of: viewModel.selectedType) { _, newValue in
                    viewModel.selectType(newValue)
                }

                // Category chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.categories, id: \.self) { category in
                            CategoryChip(
                                title: category.capitalized,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                viewModel.selectCategory(category)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // LazyVGrid of KanaChartCell
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.kanaGrid) { kana in
                            KanaChartCell(
                                kana: kana,
                                progress: viewModel.getProgress(for: kana)
                            ) {
                                viewModel.selectKana(kana)
                                showDetail = true
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .background(Color(hex: "f7f5f1"))
            .navigationTitle("Kana Chart")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showDetail) {
                if let selectedKana = viewModel.selectedKana {
                    KanaDetailSheet(
                        kana: selectedKana,
                        progress: viewModel.getProgress(for: selectedKana)
                    )
                }
            }
        }
    }
}

// MARK: - CategoryChip

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color(hex: "5b554d"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "8B5CF6") : Color(hex: "faf8f4"))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color(hex: "e4ded4"), lineWidth: 1)
                )
        }
    }
}

// MARK: - KanaChartCell

private struct KanaChartCell: View {
    let kana: SharedKana
    let progress: SharedProgress?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(kana.character)
                    .font(.system(size: 32, weight: .medium, design: .serif))
                    .foregroundColor(Color(hex: "22211F"))

                Text(kana.romaji)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(hex: "8c867d"))

                // Mastery indicator
                if let progress = progress {
                    Circle()
                        .fill(masteryColor(for: progress.masteryLevel))
                        .frame(width: 8, height: 8)
                }
            }
            .frame(width: 70, height: 80)
            .background(Color(hex: "faf8f4"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "e4ded4"), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func masteryColor(for level: AppConstants.MasteryLevel) -> Color {
        switch level {
        case .new:
            return Color.gray.opacity(0.3)
        case .learning:
            return Color(hex: "FF7A1A").opacity(0.6)
        case .familiar:
            return Color(hex: "FF7A1A")
        case .mastered:
            return Color(hex: "34D399")
        }
    }
}

// MARK: - KanaDetailSheet

struct KanaDetailSheet: View {
    let kana: SharedKana
    let progress: SharedProgress?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Large kana display
                Text(kana.character)
                    .font(.system(size: 120, weight: .medium, design: .serif))
                    .foregroundColor(Color(hex: "22211F"))

                // Romaji
                Text(kana.romaji)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(hex: "5b554d"))

                // Mastery badge
                if let progress = progress {
                    MasteryBadge(level: progress.masteryLevel)
                } else {
                    MasteryBadge(level: .new)
                }

                // Stats
                if let progress = progress {
                    HStack(spacing: 32) {
                        DetailStatItem(title: "Correct", value: "\(progress.correctCount)")
                        DetailStatItem(title: "Mistakes", value: "\(progress.mistakeCount)")
                        DetailStatItem(title: "Accuracy", value: "\(Int(progress.accuracy * 100))%")
                    }
                    .padding(.top, 8)
                }

                Spacer()
            }
            .padding(.top, 40)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "f7f5f1"))
            .navigationTitle(kana.kanaType.rawValue.capitalized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "8B5CF6"))
                }
            }
        }
    }
}

// MARK: - DetailStatItem

private struct DetailStatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "22211F"))

            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(hex: "8c867d"))
        }
    }
}

// MARK: - Previews

#Preview("KanaChartView") {
    KanaChartView()
}