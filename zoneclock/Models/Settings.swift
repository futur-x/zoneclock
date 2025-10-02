//
//  Settings.swift
//  zoneclock
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Contract Version: 1.0.0
//

import Foundation

/// 音效类型 - 微休息声音
enum SoundType: String, Codable, CaseIterable {
    case bell = "dingling"          // 钵声
    case woodfish = "muyu"           // 木鱼声
    case waterdrop = "shuidi"        // 水滴声

    var displayName: String {
        switch self {
        case .bell: return "钵声"
        case .woodfish: return "木鱼声"
        case .waterdrop: return "水滴声"
        }
    }

    var fileName: String {
        return self.rawValue
    }
}

/// 主题类型
enum Theme: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"

    var displayName: String {
        switch self {
        case .light: return "浅色"
        case .dark: return "深色"
        case .auto: return "跟随系统"
        }
    }
}

/// 音效设置
struct SoundSettings: Codable {
    var soundType: SoundType = .bell        // 微休息声音
    var volume: Float = 0.7
    var vibrationEnabled: Bool = true
}

/// 微休息间隔设置
struct MicroBreakInterval: Codable {
    var min: Int = 120              // 最小间隔2分钟（秒）
    var max: Int = 300              // 最大间隔5分钟（秒）
}

/// 用户设置模型 - 符合契约定义
struct Settings: Codable {
    // MARK: - 必需字段（契约要求）
    var focusDuration: Int = 90     // 专注时长（分钟）15-180
    var breakDuration: Int = 20     // 休息时长（分钟）5-60

    // MARK: - 可选字段
    var microBreakInterval = MicroBreakInterval()
    var soundSettings = SoundSettings()
    var dndEnabled: Bool = false    // 勿扰模式
    var theme: Theme = .auto
    var notificationEnabled: Bool = true

    // MARK: - 验证方法（契约验证规则）

    /// 验证专注时长
    func validateFocusDuration() -> Bool {
        return focusDuration >= 15 && focusDuration <= 180
    }

    /// 验证休息时长
    func validateBreakDuration() -> Bool {
        return breakDuration >= 5 && breakDuration <= 60
    }

    /// 验证微休息间隔
    func validateMicroBreakInterval() -> Bool {
        return microBreakInterval.min >= 120 &&
               microBreakInterval.max <= 300 &&
               microBreakInterval.min <= microBreakInterval.max
    }

    /// 验证音量
    func validateVolume() -> Bool {
        return soundSettings.volume >= 0 && soundSettings.volume <= 1
    }

    /// 验证所有设置
    func validate() -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []

        if !validateFocusDuration() {
            errors.append("专注时长必须在15-180分钟之间")
        }

        if !validateBreakDuration() {
            errors.append("休息时长必须在5-60分钟之间")
        }

        if !validateMicroBreakInterval() {
            errors.append("微休息间隔必须在2-5分钟之间")
        }

        if !validateVolume() {
            errors.append("音量必须在0-1之间")
        }

        return (errors.isEmpty, errors)
    }

    // MARK: - 默认设置

    static var `default`: Settings {
        return Settings()
    }

    // MARK: - UserDefaults 操作

    /// 保存到 UserDefaults
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: "userSettings")
        }
    }

    /// 从 UserDefaults 加载
    static func load() -> Settings {
        guard let data = UserDefaults.standard.data(forKey: "userSettings"),
              let settings = try? JSONDecoder().decode(Settings.self, from: data) else {
            return Settings.default
        }
        return settings
    }
}