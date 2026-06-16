import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home
        case practice
        case words
        case chart
        case settings

        var title: String {
            rawValue.capitalized
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .practice: return "pencil"
            case .words: return "book.closed.fill"
            case .chart: return "square.grid.2x2"
            case .settings: return "gearshape"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(Tab.home.title, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)

            PracticeView()
                .tabItem {
                    Label(Tab.practice.title, systemImage: Tab.practice.icon)
                }
                .tag(Tab.practice)

            WordsView()
                .tabItem {
                    Label(Tab.words.title, systemImage: Tab.words.icon)
                }
                .tag(Tab.words)

            KanaChartView()
                .tabItem {
                    Label(Tab.chart.title, systemImage: Tab.chart.icon)
                }
                .tag(Tab.chart)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(LearningTheme.red)
        .onChange(of: selectedTab) { _, _ in
            HapticService.shared.selection()
        }
    }
}

// MARK: - Previews

#Preview("ContentView") {
    ContentView()
}
