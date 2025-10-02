//
//  Cycle.swift
//  zoneclock
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Contract Version: 1.0.0
//

import Foundation

/// 专注周期状态
enum CycleStatus: String, Codable {
    case active = "active"          // 活跃专注
    case paused = "paused"          // 已暂停
    case completed = "completed"    // 已完成
    case stopped = "stopped"        // 已停止
}

/// 专注周期模型 - 符合契约定义
struct Cycle: Identifiable, Codable {
    // MARK: - 必需字段（契约要求）
    let cycleId: UUID
    var status: CycleStatus
    let startTime: Date
    let duration: Int               // 计划时长（分钟）

    // MARK: - 可选字段
    var endTime: Date?
    var actualDuration: Int = 0     // 实际专注时长（秒）
    var pausedDuration: Int = 0     // 暂停总时长（秒）
    var microBreaks: Int = 0        // 微休息次数
    var completionRate: Float {     // 完成率
        guard duration > 0 else { return 0 }
        let plannedSeconds = Float(duration * 60)

        // 如果周期还在进行中，使用实时计算
        if status == .active || status == .paused {
            let currentDuration = getCurrentDuration()
            return min(1.0, Float(currentDuration) / plannedSeconds)
        }

        // 已完成或停止的周期使用记录的 actualDuration
        return Float(actualDuration) / plannedSeconds
    }

    /// 获取当前实时时长（秒）
    func getCurrentDuration() -> Int {
        let elapsed = Int(Date().timeIntervalSince(startTime))

        // 如果当前是暂停状态，需要减去暂停时间
        if status == .paused, let pauseStart = pauseStartTime {
            let currentPauseDuration = Int(Date().timeIntervalSince(pauseStart))
            return elapsed - pausedDuration - currentPauseDuration
        }

        return elapsed - pausedDuration
    }

    // MARK: - 暂停相关
    private var pauseStartTime: Date?

    // MARK: - Identifiable
    var id: UUID { cycleId }

    // MARK: - 初始化
    init(duration: Int = 90) {
        self.cycleId = UUID()
        self.status = .active
        self.startTime = Date()
        self.duration = duration
    }

    // MARK: - 业务逻辑方法

    /// 暂停周期
    mutating func pause() {
        guard status == .active else { return }
        status = .paused
        pauseStartTime = Date()
    }

    /// 恢复周期
    mutating func resume() {
        guard status == .paused, let pauseStart = pauseStartTime else { return }
        status = .active
        pausedDuration += Int(Date().timeIntervalSince(pauseStart))
        pauseStartTime = nil
    }

    /// 停止周期
    mutating func stop() {
        guard status == .active || status == .paused else { return }
        if status == .paused, let pauseStart = pauseStartTime {
            pausedDuration += Int(Date().timeIntervalSince(pauseStart))
        }
        status = .stopped
        endTime = Date()
        actualDuration = Int(endTime!.timeIntervalSince(startTime)) - pausedDuration
    }

    /// 完成周期
    mutating func complete() {
        guard status == .active else { return }
        status = .completed
        endTime = Date()
        actualDuration = Int(endTime!.timeIntervalSince(startTime)) - pausedDuration
    }

    /// 记录微休息
    mutating func recordMicroBreak() {
        microBreaks += 1
    }

    /// 获取剩余时间（秒）
    func remainingTime() -> Int {
        let plannedSeconds = duration * 60
        let elapsedTime = actualDuration + pausedDuration
        return max(0, plannedSeconds - elapsedTime)
    }

    /// 获取当前进度（0.0 - 1.0）
    func progress() -> Float {
        return min(1.0, completionRate)
    }
}