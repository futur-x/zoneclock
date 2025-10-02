//
//  TimerController.swift
//  zoneclock
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Contract Version: 1.0.0
//

import Foundation
import Combine

/// 计时控制器 - 管理专注和休息计时
class TimerController: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var elapsedTime: Int = 0      // 已用时间（秒）
    @Published private(set) var remainingTime: Int = 0    // 剩余时间（秒）
    @Published private(set) var currentPhase: TimerPhase = .idle

    // MARK: - Private Properties
    private var timer: Timer?
    private var microBreakTimer: Timer?
    private var nextMicroBreakTime: Int = 0
    private var microBreakCountdown: Int = 0
    private weak var stateManager: StateManager?
    private weak var notificationService: NotificationService?

    // MARK: - Timer Phase
    enum TimerPhase {
        case idle
        case focusing
        case microBreak
        case longBreak
    }

    // MARK: - Singleton
    static let shared = TimerController()

    // MARK: - Initialization
    private init() {
        self.stateManager = StateManager.shared
    }

    // MARK: - Timer Control Methods

    /// 开始专注周期计时
    func startFocusCycle() {
        guard let stateManager = stateManager,
              let cycle = stateManager.currentCycle else { return }

        currentPhase = .focusing
        remainingTime = cycle.duration * 60
        elapsedTime = 0
        isRunning = true

        // 设置下次微休息时间（随机2-5分钟）
        scheduleNextMicroBreak()

        // 启动主计时器
        startMainTimer()
    }

    /// 暂停计时
    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        microBreakTimer?.invalidate()
        microBreakTimer = nil
    }

    /// 恢复计时
    func resumeTimer() {
        guard !isRunning else { return }
        isRunning = true

        if currentPhase == .microBreak {
            startMicroBreakTimer()
        } else {
            startMainTimer()
            // 重新计算下次微休息时间
            if currentPhase == .focusing {
                scheduleNextMicroBreak()
            }
        }
    }

    /// 停止计时
    func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        microBreakTimer?.invalidate()
        microBreakTimer = nil
        currentPhase = .idle
        elapsedTime = 0
        remainingTime = 0
    }

    // MARK: - Private Timer Methods

    /// 启动主计时器
    private func startMainTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMainTimer()
        }
    }

    /// 更新主计时器
    private func updateMainTimer() {
        guard isRunning else { return }

        elapsedTime += 1
        remainingTime = max(0, remainingTime - 1)

        // 检查是否触发微休息
        if currentPhase == .focusing {
            if elapsedTime >= nextMicroBreakTime {
                triggerMicroBreak()
            }
        }

        // 检查是否完成
        if remainingTime == 0 {
            handleTimerComplete()
        }
    }

    /// 处理计时完成
    private func handleTimerComplete() {
        switch currentPhase {
        case .focusing:
            // 专注周期完成，进入大休息
            completeFocusCycle()
        case .longBreak:
            // 大休息完成
            completeBreak()
        default:
            break
        }
    }

    /// 完成专注周期
    private func completeFocusCycle() {
        pauseTimer()

        // 通知状态管理器
        _ = stateManager?.completeCycleAndStartBreak()

        // 发送通知
        notificationService?.sendCycleCompleteNotification()

        // 开始大休息计时
        startLongBreak()
    }

    /// 开始大休息
    private func startLongBreak() {
        guard let breakPeriod = stateManager?.currentBreak else { return }

        currentPhase = .longBreak
        remainingTime = breakPeriod.duration * 60
        elapsedTime = 0
        isRunning = true

        startMainTimer()
    }

    /// 完成大休息
    private func completeBreak() {
        pauseTimer()

        // 通知状态管理器
        _ = stateManager?.completeBreak()

        // 发送通知
        notificationService?.sendBreakCompleteNotification()

        // 重置计时器
        currentPhase = .idle
        remainingTime = 0
        elapsedTime = 0
    }

    // MARK: - Micro Break Methods

    /// 设置下次微休息时间
    private func scheduleNextMicroBreak() {
        // 随机2-5分钟（120-300秒）- 契约BR002
        let randomInterval = Int.random(in: 120...300)
        nextMicroBreakTime = elapsedTime + randomInterval
    }

    /// 触发微休息
    private func triggerMicroBreak() {
        guard currentPhase == .focusing,
              stateManager?.currentCycle?.status == .active else { return }

        // 记录微休息
        _ = stateManager?.recordMicroBreak()

        // 暂停主计时器
        timer?.invalidate()

        // 进入微休息阶段
        currentPhase = .microBreak
        microBreakCountdown = 10  // 固定10秒 - 契约BR003

        // 发送通知
        notificationService?.sendMicroBreakNotification()

        // 启动微休息计时器
        startMicroBreakTimer()
    }

    /// 启动微休息计时器
    private func startMicroBreakTimer() {
        microBreakTimer?.invalidate()
        microBreakTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMicroBreakTimer()
        }
    }

    /// 更新微休息计时器
    private func updateMicroBreakTimer() {
        microBreakCountdown -= 1

        if microBreakCountdown <= 0 {
            // 微休息结束
            endMicroBreak()
        }
    }

    /// 结束微休息
    private func endMicroBreak() {
        microBreakTimer?.invalidate()
        microBreakTimer = nil

        // 恢复专注状态
        currentPhase = .focusing

        // 设置下次微休息时间
        scheduleNextMicroBreak()

        // 恢复主计时器
        if isRunning {
            startMainTimer()
        }
    }

    // MARK: - Query Methods

    /// 获取格式化的剩余时间
    func formattedRemainingTime() -> String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// 获取格式化的已用时间
    func formattedElapsedTime() -> String {
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// 获取微休息倒计时
    func getMicroBreakCountdown() -> Int {
        return microBreakCountdown
    }

    /// 获取进度（0.0 - 1.0）
    func getProgress() -> Float {
        guard let totalDuration = getTotalDuration() else { return 0 }
        return Float(elapsedTime) / Float(totalDuration)
    }

    /// 获取总时长（秒）
    private func getTotalDuration() -> Int? {
        switch currentPhase {
        case .focusing:
            return stateManager?.currentCycle.map { $0.duration * 60 }
        case .longBreak:
            return stateManager?.currentBreak.map { $0.duration * 60 }
        default:
            return nil
        }
    }

    // MARK: - Service Registration

    /// 注册通知服务
    func registerNotificationService(_ service: NotificationService) {
        self.notificationService = service
    }
}

/// 通知服务协议（稍后实现）
protocol NotificationService: AnyObject {
    func sendMicroBreakNotification()
    func sendCycleCompleteNotification()
    func sendBreakCompleteNotification()
}