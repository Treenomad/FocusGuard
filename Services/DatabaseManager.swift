import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: Connection?

    // Tables
    private let usageRecords = Table("usage_records")
    private let appLimits = Table("app_limits")

    // Columns
    private let id = Expression<Int64>("id")
    private let appBundleId = Expression<String>("app_bundle_id")
    private let appName = Expression<String>("app_name")
    private let startTime = Expression<Int64>("start_time")
    private let durationSeconds = Expression<Int64>("duration_seconds")
    private let dailyLimitSeconds = Expression<Int64>("daily_limit_seconds")

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
            let appFolder = URL(fileURLWithPath: path).appendingPathComponent("FocusGuard")

            try FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

            let dbPath = appFolder.appendingPathComponent("focusguard.sqlite3").path
            db = try Connection(dbPath)

            try createTables()
        } catch {
            print("Database setup failed: \(error)")
        }
    }

    private func createTables() throws {
        try db?.run(usageRecords.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(appBundleId)
            t.column(appName)
            t.column(startTime)
            t.column(durationSeconds, defaultValue: 0)
        })

        try db?.run(appLimits.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(appBundleId, unique: true)
            t.column(dailyLimitSeconds)
        })

        // Create indexes
        try db?.run(usageRecords.createIndex(startTime, ifNotExists: true))
        try db?.run(usageRecords.createIndex(appBundleId, ifNotExists: true))
    }

    func insertUsageRecord(bundleId: String, appName: String, duration: Int) {
        do {
            let insert = usageRecords.insert(
                appBundleId <- bundleId,
                self.appName <- appName,
                startTime <- Int64(Date().timeIntervalSince1970),
                durationSeconds <- Int64(duration)
            )
            try db?.run(insert)
        } catch {
            print("Insert failed: \(error)")
        }
    }

    func updateUsageDuration(bundleId: String, duration: Int) {
        // Find latest record for this app and update
        do {
            let query = usageRecords.filter(appBundleId == bundleId).order(startTime.desc).limit(1)
            if let row = try db?.pluck(query) {
                let recordId = row[id]
                let update = usageRecords.filter(id == recordId)
                try db?.run(update.update(durationSeconds += Int64(duration)))
            }
        } catch {
            print("Update failed: \(error)")
        }
    }

    func getTodayUsage() -> [UsageRecord] {
        var records: [UsageRecord] = []

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let startTimestamp = Int64(startOfDay.timeIntervalSince1970)

        do {
            let query = usageRecords.filter(startTime >= startTimestamp).order(startTime.desc)
            for row in try db?.prepare(query) ?? AnySequence([]) {
                let record = UsageRecord(
                    id: row[id],
                    appBundleId: row[appBundleId],
                    appName: row[self.appName],
                    startTime: Date(timeIntervalSince1970: TimeInterval(row[startTime])),
                    durationSeconds: Int(row[durationSeconds])
                )
                records.append(record)
            }
        } catch {
            print("Query failed: \(error)")
        }

        return records
    }

    func getTopAppsToday(limit: Int = 5) -> [(appName: String, bundleId: String, totalDuration: Int)] {
        let todayRecords = getTodayUsage()
        var appTotals: [String: (name: String, duration: Int)] = [:]

        for record in todayRecords {
            let existing = appTotals[record.appBundleId]?.duration ?? 0
            appTotals[record.appBundleId] = (name: record.appName, duration: existing + record.durationSeconds)
        }

        return appTotals.sorted { $0.value.duration > $1.value.duration }.prefix(limit).map { (appName: $0.value.name, bundleId: $0.key, totalDuration: $0.value.duration) }
    }

    // MARK: - Limit Management

    func getLimit(for bundleId: String) -> Int? {
        do {
            let query = appLimits.filter(appBundleId == bundleId)
            if let row = try db?.pluck(query) {
                return Int(row[dailyLimitSeconds])
            }
        } catch {
            print("Query limit failed: \(error)")
        }
        return nil
    }

    func setLimit(for bundleId: String, limitSeconds: Int) {
        do {
            let insert = appLimits.insert(
                or: .replace,
                appBundleId <- bundleId,
                dailyLimitSeconds <- Int64(limitSeconds)
            )
            try db?.run(insert)
        } catch {
            print("Set limit failed: \(error)")
        }
    }

    func getAllLimits() -> [String: Int] {
        var limits: [String: Int] = [:]
        do {
            for row in try db?.prepare(appLimits) ?? AnySequence([]) {
                limits[row[appBundleId]] = Int(row[dailyLimitSeconds])
            }
        } catch {
            print("Query all limits failed: \(error)")
        }
        return limits
    }

    func deleteLimit(for bundleId: String) {
        do {
            let query = appLimits.filter(appBundleId == bundleId)
            try db?.run(query.delete())
        } catch {
            print("Delete limit failed: \(error)")
        }
    }
}