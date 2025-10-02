//
//  StateManager.swift
//  zoneclock
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Contract Version: 1.0.0
//

import Foundation
import Combine

/// 应用状态 - 符合契约状态定义
enum AppState: String {
    case uninitialized = "uninitialized"   // 未初始化
    case ready = "ready"                   // 就绪
    case focusing = "focusing"             // 专注中
    case resting = "resting"               // 休息中
}

/// 状态管理器 - 管理应用整体状态转换
class StateManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var currentState: AppState = .uninitialized
    @Published private(set) var currentCycle: Cycle?
    @Published private(set) var currentBreak: LongBreak?
    @Published private(set) var microBreaks: [MicroBreak] = []
    @Published private(set) var isDNDEnabled: Bool = false

    // MARK: - Private Properties
    private var settings: Settings
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Singleton
    static let shared = StateManager()

    // MARK: - Initialization
    private init() {
        self.settings = Settings.load()
        checkInitialization()
    }

    // MARK: - State Transitions (契约定义的状态转换)

    /// 检查初始化状态
    private func checkInitialization() {
        let onboardingCompleted = UserDefaults.standard.bool(forKey: "onboardingCompleted")
        if onboardingCompleted {
            transitionTo(.ready)
        }
    }

    /// 完成引导
    func completeOnboarding() {
        guard currentState == .uninitialized else { return }
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        transitionTo(.ready)
    }

    /// 开始专注周期 - 对应 #REF-UJ-1
    func startFocusCycle(duration: Int? = nil) -> Result<Cycle, AppError> {
        guard currentState == .ready else {
            return .failure(.invalidState("已有活跃周期存在"))
        }

        let cycleDuration = duration ?? settings.focusDuration
        let cycle = Cycle(duration: cycleDuration)

        currentCycle = cycle
        microBreaks.removeAll()
        transitionTo(.focusing)

        // 保存当前周期ID
        UserDefaults.standard.set(cycle.cycleId.uuidString, forKey: "currentCycleId")

        return .success(cycle)
    }

    /// 暂停当前周期 - 对应 #REF-UJ-3
    func pauseCycle() -> Result<Void, AppError> {
        guard currentState == .focusing,
              var cycle = currentCycle,
              cycle.status == .active else {
            return .failure(.invalidState("周期状态不允许暂停"))
        }

        cycle.pause()
        currentCycle = cycle
        return .success(())
    }

    /// 恢复当前周期 - 对应 #REF-UJ-3
    func resumeCycle() -> Result<Void, AppError> {
        guard currentState == .focusing,
              var cycle = currentCycle,
              cycle.status == .paused else {
            return .failure(.invalidState("周期状态不允许恢复"))
        }

        cycle.resume()
        currentCycle = cycle
        return .success(())
    }

    /// 停止当前周期
    func stopCycle() -> Result<Void, AppError> {
        guard currentState == .focusing,
              var cycle = currentCycle else {
            return .failure(.invalidState("没有活跃的周期"))
        }

        cycle.stop()
        currentCycle = cycle

        // 保存周期记录（即使是停止的）
        let record = CycleRecord(fromCycle: cycle)
        DataStore.shared.saveCycleRecord(record)
        print("⏹️ Cycle stopped and saved: \(record.actualDuration)s")

        transitionTo(.ready)

        // 清除当前周期ID
        UserDefaults.standard.removeObject(forKey: "currentCycleId")

        return .success(())
    }

    /// 完成专注周期，进入大休息 - 对应 #REF-UJ-4
    func completeCycleAndStartBreak() -> Result<LongBreak, AppError> {
        guard currentState == .focusing,
              var cycle = currentCycle else {
            return .failure(.invalidState("没有活跃的周期"))
        }

        // 完成周期
        cycle.complete()
        currentCycle = cycle

        // 保存周期记录到数据存储
        let record = CycleRecord(fromCycle: cycle)
        DataStore.shared.saveCycleRecord(record)
        print("✅ Cycle completed and saved: \(record.actualDuration)s")

        // 开始大休息
        let longBreak = LongBreak(cycleId: cycle.cycleId, duration: settings.breakDuration)
        currentBreak = longBreak
        transitionTo(.resting)

        return .success(longBreak)
    }

    /// 记录微休息 - 对应 #REF-UJ-2
    func recordMicroBreak() -> Result<MicroBreak, AppError> {
        guard currentState == .focusing,
              var cycle = currentCycle,
              cycle.status == .active else {
            return .failure(.invalidState("暂停状态下不触发微休息"))
        }

        let microBreak = MicroBreak(
            cycleId: cycle.cycleId,
            breakCount: microBreaks.count + 1
        )

        microBreaks.append(microBreak)
        cycle.recordMicroBreak()
        currentCycle = cycle

        return .success(microBreak)
    }

    /// 完成大休息
    func completeBreak() -> Result<Void, AppError> {
        guard currentState == .resting,
              var longBreak = currentBreak else {
            return .failure(.invalidState("没有活跃的休息"))
        }

        longBreak.complete()
        currentBreak = nil
        currentCycle = nil
        transitionTo(.ready)

        // 清除当前周期ID
        UserDefaults.standard.removeObject(forKey: "currentCycleId")

        return .success(())
    }

    /// 跳过大休息
    func skipBreak() -> Result<Void, AppError> {
        guard currentState == .resting,
              var longBreak = currentBreak else {
            return .failure(.invalidState("没有活跃的休息"))
        }

        longBreak.skip()
        currentBreak = nil
        currentCycle = nil
        transitionTo(.ready)

        // 清除当前周期ID
        UserDefaults.standard.removeObject(forKey: "currentCycleId")

        return .success(())
    }

    // MARK: - Settings Management

    /// 更新设置
    func updateSettings(_ newSettings: Settings) -> Result<Void, AppError> {
        let validation = newSettings.validate()
        guard validation.isValid else {
            return .failure(.validationError(validation.errors.joined(separator: ", ")))
        }

        self.settings = newSettings
        settings.save()
        return .success(())
    }

    /// 切换勿扰模式
    func toggleDND(_ enabled: Bool) {
        isDNDEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "dndEnabled")
    }

    // MARK: - State Management

    /// 状态转换
    private func transitionTo(_ newState: AppState) {
        // 验证状态转换是否合法（根据契约）
        guard isValidTransition(from: currentState, to: newState) else {
            print("Invalid state transition: \(currentState) -> \(newState)")
            return
        }

        currentState = newState
        print("State transitioned to: \(newState)")
    }

    /// 验证状态转换是否合法
    private func isValidTransition(from: AppState, to: AppState) -> Bool {
        switch (from, to) {
        case (.uninitialized, .ready),
             (.ready, .focusing),
             (.focusing, .resting),
             (.focusing, .ready),
             (.resting, .ready):
            return true
        default:
            return false
        }
    }

    // MARK: - Query Methods

    /// 获取当前设置
    func getSettings() -> Settings {
        return settings
    }

    /// 是否有活跃的周期
    func hasActiveCycle() -> Bool {
        return currentCycle != nil && currentState == .focusing
    }

    /// 获取当前周期进度
    func getCurrentProgress() -> Float {
        if let cycle = currentCycle {
            return cycle.progress()
        } else if let breakPeriod = currentBreak {
            return breakPeriod.progress()
        }
        return 0
    }

    /// 获取剩余时间（秒）
    func getRemainingTime() -> Int {
        if let cycle = currentCycle {
            return cycle.remainingTime()
        } else if let breakPeriod = currentBreak {
            return breakPeriod.remainingTime()
        }
        return 0
    }
}

/// 应用错误类型
enum AppError: LocalizedError {
    case invalidState(String)
    case validationError(String)
    case notFound(String)
    case networkError(String)
    case storageError(String)

    var errorDescription: String? {
        switch self {
        case .invalidState(let message):
            return "状态错误: \(message)"
        case .validationError(let message):
            return "验证失败: \(message)"
        case .notFound(let message):
            return "未找到: \(message)"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .storageError(let message):
            return "存储错误: \(message)"
        }
    }
}