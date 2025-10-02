//
//  Break.swift
//  zoneclock
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Contract Version: 1.0.0
//

import Foundation

/// 微休息模型 - 符合契约定义
struct MicroBreak: Identifiable, Codable {
    let breakId: UUID
    let cycleId: UUID
    let triggerTime: Date
    let duration: Int = 10          // 固定10秒（契约BR003）
    var breakCount: Int             // 本周期第几次微休息
    var nextBreakIn: Int?           // 下次微休息间隔（秒）

    var id: UUID { breakId }

    init(cycleId: UUID, breakCount: Int) {
        self.breakId = UUID()
        self.cycleId = cycleId
        self.triggerTime = Date()
        self.breakCount = breakCount

        // 随机生成下次微休息间隔（2-5分钟）- 契约BR002
        self.nextBreakIn = Int.random(in: 120...300)
    }
}

/// 大休息状态
enum LongBreakStatus: String, Codable {
    case active = "active"
    case completed = "completed"
    case skipped = "skipped"
}

/// 大休息模型 - 符合契约定义
struct LongBreak: Identifiable, Codable {
    let breakId: UUID
    let cycleId: UUID
    let startTime: Date
    let duration: Int               // 休息时长（分钟）
    var status: LongBreakStatus
    var endTime: Date?

    var id: UUID { breakId }

    init(cycleId: UUID, duration: Int = 20) {
        self.breakId = UUID()
        self.cycleId = cycleId
        self.startTime = Date()
        self.duration = duration
        self.status = .active
    }

    /// 完成休息
    mutating func complete() {
        status = .completed
        endTime = Date()
    }

    /// 跳过休息
    mutating func skip() {
        status = .skipped
        endTime = Date()
    }

    /// 获取剩余时间（秒）
    func remainingTime() -> Int {
        let plannedSeconds = duration * 60
        let elapsedTime = Int(Date().timeIntervalSince(startTime))
        return max(0, plannedSeconds - elapsedTime)
    }

    /// 获取进度（0.0 - 1.0）
    func progress() -> Float {
        let plannedSeconds = Float(duration * 60)
        let elapsedTime = Float(Date().timeIntervalSince(startTime))
        return min(1.0, elapsedTime / plannedSeconds)
    }
}