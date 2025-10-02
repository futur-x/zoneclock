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

    /// 获取本周统计（过去7天）
    func getWeekStatistics() -> [DailyStatistics] {
        var weekStats: [DailyStatistics] = []
        let calendar = Calendar.current

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)

            let records = loadAllRecords().filter { record in
                calendar.isDate(record.date, inSameDayAs: startOfDay)
            }

            weekStats.append(calculateStatistics(from: records))
        }

        return weekStats.reversed() // 从最早到最新
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
    private func calculateStatistics(from records: [CycleRecord]) -> DailyStatistics {
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
            totalFocusTime: totalFocusTime,
            completedCycles: completedCycles,
            microBreaksCount: microBreaksCount,
            completionRate: avgCompletionRate,
            totalBreakTime: totalBreakTime
        )
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
