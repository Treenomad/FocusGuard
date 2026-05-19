import Foundation

struct UsageRecord: Identifiable, Codable {
    let id: Int64?
    let appBundleId: String
    let appName: String
    let startTime: Date
    var durationSeconds: Int

    init(id: Int64? = nil, appBundleId: String, appName: String, startTime: Date, durationSeconds: Int = 0) {
        self.id = id
        self.appBundleId = appBundleId
        self.appName = appName
        self.startTime = startTime
        self.durationSeconds = durationSeconds
    }
}

struct AppLimit: Identifiable, Codable {
    let id: Int64?
    let appBundleId: String
    let dailyLimitSeconds: Int

    init(id: Int64? = nil, appBundleId: String, dailyLimitSeconds: Int) {
        self.id = id
        self.appBundleId = appBundleId
        self.dailyLimitSeconds = dailyLimitSeconds
    }
}

struct DailySummary {
    let date: Date
    let totalUsage: Int
    let appBreakdown: [String: Int]
}