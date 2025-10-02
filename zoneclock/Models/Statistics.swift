//
//  Statistics.swift
//  zoneclock
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Contract Version: 1.0.0
//

import Foundation

/// 每日统计数据 - 符合契约定义
struct DailyStatistics: Codable {
    let date: Date
    var totalCycles: Int = 0           // 总周期数
    var completedCycles: Int = 0       // 完成的周期数
    var totalFocusTime: Int = 0        // 总专注时长（分钟）
    var totalBreakTime: Int = 0        // 总休息时长（分钟）
    var microBreaksCount: Int = 0      // 微休息总次数

    var completionRate: Float {        // 完成率
        guard totalCycles > 0 else { return 0 }
        return Float(completedCycles) / Float(totalCycles)
    }

    var averageFocusDuration: Int {    // 平均专注时长（分钟）
        guard completedCycles > 0 else { return 0 }
        return totalFocusTime / completedCycles
    }

    init(date: Date = Date()) {
        // 设置为当天的开始时间
        let calendar = Calendar.current
        self.date = calendar.startOfDay(for: date)
    }

    init(date: Date = Date(),
         totalFocusTime: Int,
         completedCycles: Int,
         microBreaksCount: Int,
         completionRate: Float,
         totalBreakTime: Int) {
        let calendar = Calendar.current
        self.date = calendar.startOfDay(for: date)
        self.totalFocusTime = totalFocusTime
        self.completedCycles = completedCycles
        self.microBreaksCount = microBreaksCount
        self.totalBreakTime = totalBreakTime
        // completionRate 是计算属性，不需要设置
        // totalCycles 可以从 completedCycles 计算得出（假设所有周期都完成了，或者保持为0）
        self.totalCycles = completedCycles
    }
}

/// 周期统计数据 - 符合契约定义
struct CycleStatistics: Codable {
    let cycleId: UUID
    let startTime: Date
    let endTime: Date
    let plannedDuration: Int           // 计划时长（分钟）
    let actualFocusTime: Int           // 实际专注时间（秒）
    let pausedTime: Int                // 暂停时间（秒）
    let microBreaks: [MicroBreakRecord] // 微休息记录

    var completionRate: Float {        // 完成率
        let plannedSeconds = Float(plannedDuration * 60)
        return Float(actualFocusTime) / plannedSeconds
    }
}

/// 微休息记录
struct MicroBreakRecord: Codable {
    let time: Date
    let intervalSinceLastBreak: Int    // 距上次休息的间隔（秒）
}

/// 趋势分析数据 - 符合契约定义
struct TrendAnalysis: Codable {
    let period: String                     // 分析周期
    var averageDailyFocusTime: Int = 0     // 平均每日专注时长（分钟）
    var averageCompletionRate: Float = 0   // 平均完成率
    var peakFocusHours: [Int] = []         // 高峰专注时段（0-23小时）
    var weeklyPattern: [String: Int] = [:] // 每周专注模式
    var improvement: Float = 0              // 相比上期提升率

    init(period: String) {
        self.period = period
    }

    /// 分析每日数据生成趋势
    mutating func analyze(dailyStats: [DailyStatistics]) {
        guard !dailyStats.isEmpty else { return }

        // 计算平均每日专注时长
        let totalFocus = dailyStats.reduce(0) { $0 + $1.totalFocusTime }
        averageDailyFocusTime = totalFocus / dailyStats.count

        // 计算平均完成率
        let totalRate = dailyStats.reduce(Float(0)) { $0 + $1.completionRate }
        averageCompletionRate = totalRate / Float(dailyStats.count)

        // 分析高峰时段（这里简化处理）
        // 实际应该根据周期的开始时间统计
        peakFocusHours = [9, 10, 14, 15] // 默认上午和下午的高峰时段

        // 分析每周模式
        let calendar = Calendar.current
        for stat in dailyStats {
            let weekday = calendar.component(.weekday, from: stat.date)
            let weekdayName = calendar.weekdaySymbols[weekday - 1]
            weeklyPattern[weekdayName, default: 0] += stat.totalFocusTime
        }
    }
}

/// 同步状态 - 符合契约定义
struct SyncStatus: Codable {
    var lastSyncAt: Date?
    var nextSyncAt: Date?
    var pendingChanges: Int = 0
    var syncEnabled: Bool = true
    var connectionStatus: ConnectionStatus = .offline
}

enum ConnectionStatus: String, Codable {
    case online = "online"
    case offline = "offline"
    case syncing = "syncing"
}

/// 同步结果 - 符合契约定义
struct SyncResult: Codable {
    enum Status: String, Codable {
        case success = "success"
        case pending = "pending"
        case conflict = "conflict"
        case failed = "failed"
    }

    var syncStatus: Status
    var syncedAt: Date
    var itemsSynced: Int = 0
    var conflicts: [SyncConflict] = []
}

/// 同步冲突
struct SyncConflict: Codable {
    enum Resolution: String, Codable {
        case keepLocal = "keep_local"
        case keepRemote = "keep_remote"
        case merged = "merged"
    }

    let type: String
    let localVersion: String
    let remoteVersion: String
    var resolution: Resolution
}