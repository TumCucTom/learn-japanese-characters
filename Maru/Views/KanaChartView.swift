import SwiftUI

// MARK: - KanaChartView

struct KanaChartView: View {
    @StateObject private var viewModel = KanaChartViewModel()
    @State private var showDetail = false
    @State private var showPractice = false
    @State private var selectedPracticeKana: [SharedKana] = []

    private let columns = [
        GridItem(.adaptive(minimum: 62, maximum: 78), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    typePicker
                    categoryChips

                    if viewModel.selectedCategory == "basic" {
                        rowList
                    } else {
                        kanaGrid
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .background(LearningTheme.cream.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 84)
            }
            .navigationTitle("Kana Rows")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showDetail) {
                if let selectedKana = viewModel.selectedKana {
                    KanaDetailSheet(
                        kana: selectedKana,
                        progress: viewModel.getProgress(for: selectedKana)
                    )
                }
            }
            .navigationDestination(isPresented: $showPractice) {
                PracticeView(initialKana: selectedPracticeKana, initialExerciseType: .multipleChoice, hidesTabBar: true)
            }
            .onAppear {
                viewModel.loadProgress()
                viewModel.loadKanaGrid()
            }
        }
    }

    private var typePicker: some View {
        Picker("Kana Type", selection: $viewModel.selectedType) {
            ForEach(AppConstants.KanaType.allCases, id: \.self) { type in
                Text(type.rawValue.capitalized)
                    .tag(type)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.selectedType) { _, newValue in
            viewModel.selectType(newValue)
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.categories, id: \.self) { category in
                    CategoryChip(
                        title: category.capitalized,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectCategory(category)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var rowList: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.rows) { row in
                KanaRowCard(
                    row: row,
                    status: viewModel.status(for: row),
                    progress: viewModel.practicedFraction(for: row),
                    onKanaTap: { kana in
                        viewModel.selectKana(kana)
                        showDetail = true
                    },
                    onDrill: {
                        HapticService.shared.selection()
                        selectedPracticeKana = row.kana
                        showPractice = true
                    }
                )
            }
        }
    }

    private var kanaGrid: some View {
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
        .padding(.top, 4)
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
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(isSelected ? .white : LearningTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
        }
        .buttonStyle(
            LearningOutlinedButtonStyle(
                fill: isSelected ? LearningTheme.red : .white,
                pressedFill: isSelected ? LearningTheme.redDark : LearningTheme.yellowSoft
            )
        )
    }
}

// MARK: - KanaRowCard

private struct KanaRowCard: View {
    let row: KanaLearningPath.Row
    let status: KanaLearningPath.RowStatus
    let progress: Double
    let onKanaTap: (SharedKana) -> Void
    let onDrill: () -> Void

    private var isLocked: Bool { status == .locked }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(row.romajiPrefix.uppercased()) Row")
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundColor(isLocked ? LearningTheme.softInk : LearningTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(statusLabel)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(statusColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(LearningTheme.softInk)
                } else {
                    Button(action: onDrill) {
                        Text("Drill")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(LearningOutlinedButtonStyle(fill: LearningTheme.red, pressedFill: LearningTheme.redDark))
                }
            }

            HStack(spacing: 7) {
                ForEach(row.kana) { kana in
                    KanaCard(
                        kana: kana,
                        fill: cardFill(for: kana),
                        isLocked: isLocked
                    ) {
                        onKanaTap(kana)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(isLocked ? 0.62 : 1)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LearningTheme.locked)
                    Capsule()
                        .fill(statusColor)
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 8)
            .overlay(Capsule().stroke(LearningTheme.line, lineWidth: 1.25))
        }
        .padding(12)
        .background(isLocked ? LearningTheme.locked.opacity(0.75) : .white)
        .clipShape(RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous)
                .stroke(LearningTheme.line, lineWidth: LearningTheme.heavyLine)
        )
    }

    private var statusLabel: String {
        switch status {
        case .locked:
            return "Unlock after the previous row"
        case .unlocked:
            return "Ready"
        case .learning:
            return "In progress"
        case .mastered:
            return "Mastered"
        }
    }

    private var statusColor: Color {
        switch status {
        case .locked:
            return LearningTheme.softInk
        case .unlocked:
            return LearningTheme.red
        case .learning:
            return LearningTheme.yellow
        case .mastered:
            return LearningTheme.green
        }
    }

    private func cardFill(for kana: SharedKana) -> Color {
        guard !isLocked else { return LearningTheme.locked }
        return kana.id.hashValue.isMultiple(of: 3) ? LearningTheme.redSoft : .white
    }
}

// MARK: - KanaChartCell

private struct KanaChartCell: View {
    let kana: SharedKana
    let progress: SharedProgress?
    let action: () -> Void

    var body: some View {
        KanaCard(kana: kana, fill: masteryFill) {
            action()
        }
    }

    private var masteryFill: Color {
        switch progress?.masteryLevel {
        case .mastered:
            return LearningTheme.greenSoft
        case .familiar:
            return LearningTheme.redSoft
        case .learning:
            return LearningTheme.yellowSoft
        case .new, .none:
            return .white
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
            VStack(spacing: 26) {
                LargeKanaCard(
                    kana: kana,
                    masteryLevel: progress?.masteryLevel ?? .new
                ) {}

                VStack(spacing: 6) {
                    Text(kana.kanaType.rawValue.capitalized)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(LearningTheme.mutedInk)

                    Text(kana.category.capitalized)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(LearningTheme.ink)
                }

                MasteryBadge(level: progress?.masteryLevel ?? .new)

                if let progress {
                    HStack(spacing: 32) {
                        DetailStatItem(title: "Correct", value: "\(progress.correctCount)")
                        DetailStatItem(title: "Mistakes", value: "\(progress.mistakeCount)")
                        DetailStatItem(title: "Accuracy", value: "\(Int(progress.accuracy * 100))%")
                    }
                    .padding(.top, 6)
                }

                Spacer()
            }
            .padding(.top, 44)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(LearningTheme.cream)
            .navigationTitle(kana.romaji)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.red)
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
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundColor(LearningTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundColor(LearningTheme.softInk)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }
}

// MARK: - Previews

#Preview("KanaChartView") {
    KanaChartView()
}
