import SwiftUI
import Cocoa

struct ContentView: View {
    @ObservedObject private var viewModel = UsageViewModel()
    @State private var selectedApp: AppUsageItem?

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

            // Usage list with icons
            List(viewModel.appItems, id: \.bundleId) { item in
                AppRowView(item: item, limitMinutes: viewModel.getLimit(for: item.bundleId))
                    .onTapGesture {
                        selectedApp = item
                    }
            }
            .listStyle(.plain)

            Divider()

            // Footer
            HStack {
                Button("刷新") {
                    viewModel.refresh()
                }
                Spacer()
                Text("点击应用设置限额")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 500)
        .sheet(item: $selectedApp) { app in
            LimitSettingView(app: app, viewModel: viewModel)
        }
    }
}

struct AppUsageItem: Identifiable {
    let id = UUID()
    let appName: String
    let bundleId: String
    let totalDuration: Int
    let icon: NSImage?
}

struct AppRowView: View {
    let item: AppUsageItem
    let limitMinutes: Int?

    var body: some View {
        HStack {
            // App icon
            if let icon = item.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
                    .cornerRadius(6)
            } else {
                Image(systemName: "app.fill")
                    .font(.title)
                    .frame(width: 32, height: 32)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading) {
                Text(item.appName)
                    .font(.body)
                if let limit = limitMinutes {
                    let usedMinutes = item.totalDuration / 60
                    let progress = min(Double(usedMinutes) / Double(limit), 1.0)
                    HStack {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .frame(width: 80)
                        Text("\(usedMinutes)/\(limit)m")
                            .font(.caption2)
                            .foregroundColor(progress >= 1.0 ? .red : .secondary)
                    }
                }
            }

            Spacer()

            Text(formatDuration(item.totalDuration))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(limitMinutes != nil && item.totalDuration / 60 >= limitMinutes! ? .red : .primary)
        }
        .padding(.vertical, 8)
    }

    func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

struct LimitSettingView: View {
    let app: AppUsageItem
    @ObservedObject var viewModel: UsageViewModel
    @Environment(\.dismiss) var dismiss
    @State private var limitMinutes: Int = 30

    var body: some View {
        VStack(spacing: 20) {
            Text("设置 \(app.appName) 每日限额")
                .font(.headline)

            HStack {
                Text("限额:")
                Stepper("\(limitMinutes) 分钟", value: $limitMinutes, in: 5...480, step: 5)
            }

            HStack {
                Button("保存") {
                    viewModel.setLimit(for: app.bundleId, minutes: limitMinutes)
                    dismiss()
                }
                Button("删除限额") {
                    viewModel.removeLimit(for: app.bundleId)
                    dismiss()
                }
                .foregroundColor(.red)
                Button("取消") {
                    dismiss()
                }
            }
        }
        .padding()
        .frame(width: 350)
        .onAppear {
            if let existing = viewModel.getLimit(for: app.bundleId) {
                limitMinutes = existing
            }
        }
    }
}

class UsageViewModel: ObservableObject {
    @Published var appItems: [AppUsageItem] = []
    @Published var todayDate: String = ""

    init() {
        refresh()
        setupTimer()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .usageUpdated, object: nil)
    }

    @objc func refresh() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        todayDate = formatter.string(from: Date())

        let records = DatabaseManager.shared.getTopAppsToday(limit: 20)

        appItems = records.map { record in
            let icon = NSWorkspace.shared.icon(forFile: "/Applications/\(record.bundleId).app")
            icon.size = NSSize(width: 32, height: 32)
            return AppUsageItem(appName: record.appName, bundleId: record.bundleId, totalDuration: record.totalDuration, icon: icon)
        }
    }

    func getLimit(for bundleId: String) -> Int? {
        guard let seconds = DatabaseManager.shared.getLimit(for: bundleId) else { return nil }
        return seconds / 60
    }

    func setLimit(for bundleId: String, minutes: Int) {
        DatabaseManager.shared.setLimit(for: bundleId, limitSeconds: minutes * 60)
        refresh()
    }

    func removeLimit(for bundleId: String) {
        DatabaseManager.shared.deleteLimit(for: bundleId)
        refresh()
    }

    func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) minutes"
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