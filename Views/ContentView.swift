import SwiftUI

struct ContentView: View {
    @ObservedObject private var viewModel = UsageViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("FocusGuard")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Text(viewModel.todayDate)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Usage list
            List(viewModel.topApps, id: \.appName) { app in
                HStack {
                    Image(systemName: "app.fill")
                        .foregroundColor(.blue)
                        .frame(width: 30)

                    VStack(alignment: .leading) {
                        Text(app.appName)
                            .font(.body)
                        Text(viewModel.formatDuration(app.totalDuration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(viewModel.formatMinutes(app.totalDuration))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 8)
            }
            .listStyle(.plain)

            Divider()

            // Footer
            HStack {
                Button("刷新") {
                    viewModel.refresh()
                }
                Spacer()
                Text("每分钟自动更新")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 400)
    }
}

struct AppUsage: Identifiable {
    let id = UUID()
    let appName: String
    let totalDuration: Int
}

class UsageViewModel: ObservableObject {
    @Published var topApps: [AppUsage] = []
    @Published var todayDate: String = ""

    init() {
        refresh()
        setupTimer()

        // Listen for updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: .usageUpdated,
            object: nil
        )
    }

    @objc func refresh() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        todayDate = formatter.string(from: Date())

        let records = DatabaseManager.shared.getTopAppsToday(limit: 10)
        topApps = records.map { AppUsage(appName: $0.appName, totalDuration: $0.totalDuration) }
    }

    func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) minutes"
    }

    func formatMinutes(_ seconds: Int) -> String {
        return "\(seconds / 60)m"
    }

    private func setupTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }
}

#Preview {
    ContentView()
}