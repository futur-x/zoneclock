//
//  CycleRecord.swift
//  zoneclock
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Data persistence model for cycle records
//

import Foundation

/// 专注周期记录 - 用于持久化和统计
struct CycleRecord: Identifiable, Codable {
    let id: UUID
    let cycleId: UUID              // 关联的周期ID
    let date: Date                 // 记录日期
    let plannedDuration: Int       // 计划时长（分钟）
    let actualDuration: Int        // 实际时长（秒）
    let microBreaksCount: Int      // 微休息次数
    let completionRate: Float      // 完成率
    let wasCompleted: Bool         // 是否完成（true=完成，false=停止）

    // 自定义初始化器（从Cycle创建）
    init(fromCycle cycle: Cycle) {
        self.id = UUID()
        self.cycleId = cycle.cycleId
        self.date = cycle.endTime ?? Date()
        self.plannedDuration = cycle.duration
        self.actualDuration = cycle.actualDuration
        self.microBreaksCount = cycle.microBreaks
        self.completionRate = cycle.completionRate
        self.wasCompleted = cycle.status == .completed
    }

    // Codable 所需的初始化器
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.cycleId = try container.decode(UUID.self, forKey: .cycleId)
        self.date = try container.decode(Date.self, forKey: .date)
        self.plannedDuration = try container.decode(Int.self, forKey: .plannedDuration)
        self.actualDuration = try container.decode(Int.self, forKey: .actualDuration)
        self.microBreaksCount = try container.decode(Int.self, forKey: .microBreaksCount)
        self.completionRate = try container.decode(Float.self, forKey: .completionRate)
        self.wasCompleted = try container.decode(Bool.self, forKey: .wasCompleted)
    }

    // 显式定义 CodingKeys 以支持 Codable
    enum CodingKeys: String, CodingKey {
        case id
        case cycleId
        case date
        case plannedDuration
        case actualDuration
        case microBreaksCount
        case completionRate
        case wasCompleted
    }
}

/// 数据存储管理器
class DataStore {
    // MARK: - Singleton
    static let shared = DataStore()

    private let userDefaultsKey = "cycleRecords"

    private init() {}

    // MARK: - Save & Load

    /// 保存周期记录
    func saveCycleRecord(_ record: CycleRecord) {
        var records = loadAllRecords()
        records.append(record)

        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            print("💾 Saved cycle record: \(record.actualDuration)s, completed: \(record.wasCompleted)")
        }
    }

    /// 加载所有记录
    func loadAllRecords() -> [CycleRecord] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let records = try? JSONDecoder().decode([CycleRecord].self, from: data) else {
            return []
        }
        return records
    }

    // MARK: - Query Methods

    /// 获取今日统计
    func getTodayStatistics() -> DailyStatistics {
        let today = Calendar.current.startOfDay(for: Date())
        let records = loadAllRecords().filter { record in
            Calendar.current.isDate(record.date, inSameDayAs: today)
        }

        return calculateStatistics(from: records)
    }

    /// 获取过去7天统计（从7天前到今天）
    func getWeekStatistics() -> [DailyStatistics] {
        var weekStats: [DailyStatistics] = []
        let calendar = Calendar.current

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)

            let records = loadAllRecords().filter { record in
                calendar.isDate(record.date, inSameDayAs: startOfDay)
            }

            weekStats.append(calculateStatistics(from: records, date: startOfDay))
        }

        return weekStats.reversed() // 从7天前到今天（index 0 = 7天前, index 6 = 今天）
    }

    /// 获取指定日期范围的统计
    func getStatistics(from startDate: Date, to endDate: Date) -> DailyStatistics {
        let records = loadAllRecords().filter { record in
            record.date >= startDate && record.date <= endDate
        }

        return calculateStatistics(from: records)
    }

    // MARK: - Private Methods

    /// 从记录计算统计数据
    private func calculateStatistics(from records: [CycleRecord], date: Date = Date()) -> DailyStatistics {
        let totalFocusTime = records.reduce(0) { $0 + ($1.actualDuration / 60) } // 转换为分钟
        let completedCycles = records.filter { $0.wasCompleted }.count
        let totalCycles = records.count
        let microBreaksCount = records.reduce(0) { $0 + $1.microBreaksCount }

        // 计算平均完成率
        let avgCompletionRate: Float
        if !records.isEmpty {
            let totalRate = records.reduce(Float(0)) { $0 + $1.completionRate }
            avgCompletionRate = totalRate / Float(records.count)
        } else {
            avgCompletionRate = 0
        }

        // 计算总休息时间（假设每个完成的周期有20分钟休息）
        let totalBreakTime = completedCycles * 20

        return DailyStatistics(
            date: date,
            totalFocusTime: totalFocusTime,
            completedCycles: completedCycles,
            microBreaksCount: microBreaksCount,
            completionRate: avgCompletionRate,
            totalBreakTime: totalBreakTime
        )
    }

    // MARK: - Trend Analysis Methods

    /// 获取30天趋势数据
    func get30DaysTrend() -> (focusTimeImprovement: Float, completionRateImprovement: Float) {
        let calendar = Calendar.current
        let today = Date()

        // 获取过去30天的数据
        guard let past30DaysStart = calendar.date(byAdding: .day, value: -30, to: today) else {
            return (0, 0)
        }
        let past30DaysRecords = loadAllRecords().filter { record in
            record.date >= past30DaysStart && record.date <= today
        }

        // 获取前30天的数据（用于对比）
        guard let previous30DaysStart = calendar.date(byAdding: .day, value: -60, to: today) else {
            return (0, 0)
        }
        let previous30DaysRecords = loadAllRecords().filter { record in
            record.date >= previous30DaysStart && record.date < past30DaysStart
        }

        // 计算过去30天的平均专注时长和完成率
        let past30DaysStats = calculateStatistics(from: past30DaysRecords)
        let previous30DaysStats = calculateStatistics(from: previous30DaysRecords)

        // 计算提升率
        var focusTimeImprovement: Float = 0
        if previous30DaysStats.totalFocusTime > 0 {
            focusTimeImprovement = Float(past30DaysStats.totalFocusTime - previous30DaysStats.totalFocusTime) / Float(previous30DaysStats.totalFocusTime)
        }

        var completionRateImprovement: Float = 0
        if previous30DaysStats.completionRate > 0 {
            completionRateImprovement = (past30DaysStats.completionRate - previous30DaysStats.completionRate) / previous30DaysStats.completionRate
        }

        return (focusTimeImprovement, completionRateImprovement)
    }

    /// 获取最佳专注时段（返回每小时的效率数据）
    func getPeakFocusHours() -> [(hour: Int, productivity: Double)] {
        let records = loadAllRecords()
        let calendar = Calendar.current

        // 统计每个小时的专注数据
        var hourlyStats: [Int: (totalDuration: Int, totalCompletion: Float, count: Int)] = [:]

        for record in records {
            let hour = calendar.component(.hour, from: record.date)
            let existing = hourlyStats[hour] ?? (0, 0, 0)
            hourlyStats[hour] = (
                existing.totalDuration + record.actualDuration,
                existing.totalCompletion + record.completionRate,
                existing.count + 1
            )
        }

        // 计算每个小时的平均效率（完成率）
        var peakHours: [(hour: Int, productivity: Double)] = []
        for (hour, stats) in hourlyStats {
            if stats.count > 0 {
                let avgProductivity = Double(stats.totalCompletion) / Double(stats.count)
                peakHours.append((hour, avgProductivity))
            }
        }

        // 按效率降序排序，取前4个
        peakHours.sort { $0.productivity > $1.productivity }
        return Array(peakHours.prefix(4))
    }

    // MARK: - Utility Methods

    /// 清除所有记录（用于测试）
    func clearAllRecords() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        print("🗑️ All records cleared")
    }

    /// 获取记录总数
    func getRecordCount() -> Int {
        return loadAllRecords().count
    }
}
