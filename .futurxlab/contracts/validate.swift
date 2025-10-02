#!/usr/bin/swift
//
//  validate.swift
//  Zone Clock Contract Validator
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Contract Version: 1.0.0
//
//  Usage: swift validate.swift [path_to_project]
//

import Foundation

// MARK: - Contract Rules
struct ContractRules {
    // 文件命名规则
    static let modelFilePattern = "^[A-Z][a-zA-Z]+\\.swift$"
    static let viewFilePattern = "^[A-Z][a-zA-Z]+View\\.swift$"
    static let controllerFilePattern = "^[A-Z][a-zA-Z]+Controller\\.swift$"
    static let serviceFilePattern = "^[A-Z][a-zA-Z]+Service\\.swift$"

    // 关键常量
    static let microBreakDuration = 10  // 必须固定10秒
    static let microBreakIntervalMin = 120  // 最小2分钟
    static let microBreakIntervalMax = 300  // 最大5分钟
    static let focusDurationMin = 15
    static let focusDurationMax = 180
    static let breakDurationMin = 5
    static let breakDurationMax = 60

    // 必需的状态
    static let requiredAppStates = ["uninitialized", "ready", "focusing", "resting"]
    static let requiredCycleStates = ["active", "paused", "completed", "stopped"]

    // UserDefaults键名
    static let requiredUserDefaultsKeys = [
        "focusDuration",
        "breakDuration",
        "soundType",
        "dndEnabled",
        "notificationEnabled",
        "onboardingCompleted",
        "currentCycleId"
    ]
}

// MARK: - Validation Result
struct ValidationResult {
    let file: String
    let line: Int?
    let rule: String
    let message: String
    let severity: Severity

    enum Severity: String {
        case error = "❌ ERROR"
        case warning = "⚠️ WARNING"
        case info = "ℹ️ INFO"
    }
}

// MARK: - Contract Validator
class ContractValidator {
    private var results: [ValidationResult] = []
    private let projectPath: String

    init(projectPath: String) {
        self.projectPath = projectPath
    }

    // MARK: - Main Validation
    func validate() {
        print("🔍 Zone Clock Contract Validator v1.0.0")
        print("📁 Validating project: \(projectPath)")
        print("=" * 50)

        // 验证文件结构
        validateFileStructure()

        // 验证模型定义
        validateModels()

        // 验证控制器
        validateControllers()

        // 验证视图
        validateViews()

        // 验证业务规则
        validateBusinessRules()

        // 输出结果
        printResults()
    }

    // MARK: - File Structure Validation
    private func validateFileStructure() {
        let requiredDirs = [
            "Models",
            "Views",
            "Controllers",
            "Services"
        ]

        for dir in requiredDirs {
            let dirPath = "\(projectPath)/zoneclock/\(dir)"
            if !FileManager.default.fileExists(atPath: dirPath) {
                addResult(
                    file: "Project Structure",
                    rule: "Directory Structure",
                    message: "Required directory missing: \(dir)",
                    severity: .error
                )
            }
        }

        // 验证文件命名
        validateFileNaming()
    }

    private func validateFileNaming() {
        let modelFiles = getFiles(in: "\(projectPath)/zoneclock/Models")
        for file in modelFiles {
            if !file.matches(pattern: ContractRules.modelFilePattern) {
                addResult(
                    file: file,
                    rule: "File Naming",
                    message: "Model file should follow pattern: [A-Z][a-zA-Z]+.swift",
                    severity: .warning
                )
            }
        }
    }

    // MARK: - Model Validation
    private func validateModels() {
        // 验证 Cycle 模型
        validateCycleModel()

        // 验证 Settings 模型
        validateSettingsModel()
    }

    private func validateCycleModel() {
        let cyclePath = "\(projectPath)/zoneclock/Models/Cycle.swift"
        guard let content = readFile(cyclePath) else { return }

        // 检查必需字段
        let requiredFields = ["cycleId", "status", "startTime", "duration"]
        for field in requiredFields {
            if !content.contains("let \(field)") && !content.contains("var \(field)") {
                addResult(
                    file: "Cycle.swift",
                    rule: "Required Fields",
                    message: "Missing required field: \(field)",
                    severity: .error
                )
            }
        }

        // 检查状态枚举
        for state in ContractRules.requiredCycleStates {
            if !content.contains("case \(state)") {
                addResult(
                    file: "Cycle.swift",
                    rule: "Cycle States",
                    message: "Missing required state: \(state)",
                    severity: .error
                )
            }
        }
    }

    private func validateSettingsModel() {
        let settingsPath = "\(projectPath)/zoneclock/Models/Settings.swift"
        guard let content = readFile(settingsPath) else { return }

        // 检查验证方法
        if !content.contains("func validateFocusDuration()") {
            addResult(
                file: "Settings.swift",
                rule: "Validation Methods",
                message: "Missing focus duration validation method",
                severity: .warning
            )
        }

        // 检查范围验证
        if content.contains("focusDuration >= ") {
            // 提取并验证范围
            validateRange(in: content, field: "focusDuration",
                         min: ContractRules.focusDurationMin,
                         max: ContractRules.focusDurationMax)
        }
    }

    // MARK: - Controller Validation
    private func validateControllers() {
        validateStateManager()
        validateTimerController()
    }

    private func validateStateManager() {
        let path = "\(projectPath)/zoneclock/Controllers/StateManager.swift"
        guard let content = readFile(path) else { return }

        // 检查状态转换
        for state in ContractRules.requiredAppStates {
            if !content.contains("case \(state)") {
                addResult(
                    file: "StateManager.swift",
                    rule: "App States",
                    message: "Missing required app state: \(state)",
                    severity: .error
                )
            }
        }

        // 检查单例模式
        if !content.contains("static let shared") {
            addResult(
                file: "StateManager.swift",
                rule: "Singleton Pattern",
                message: "StateManager should use singleton pattern",
                severity: .warning
            )
        }
    }

    private func validateTimerController() {
        let path = "\(projectPath)/zoneclock/Controllers/TimerController.swift"
        guard let content = readFile(path) else { return }

        // 检查微休息固定时长
        if content.contains("microBreakCountdown = ") {
            let lines = content.components(separatedBy: .newlines)
            for (index, line) in lines.enumerated() {
                if line.contains("microBreakCountdown = ") && !line.contains("= 10") {
                    addResult(
                        file: "TimerController.swift",
                        line: index + 1,
                        rule: "BR003: Fixed Micro Break Duration",
                        message: "Micro break must be fixed at 10 seconds",
                        severity: .error
                    )
                }
            }
        }

        // 检查随机间隔
        if content.contains("Int.random") {
            if !content.contains("120...300") && !content.contains("in: 120...300") {
                addResult(
                    file: "TimerController.swift",
                    rule: "BR002: Random Micro Break Interval",
                    message: "Micro break interval must be random between 120-300 seconds",
                    severity: .error
                )
            }
        }
    }

    // MARK: - Business Rule Validation
    private func validateBusinessRules() {
        // BR001: 单周期原则
        validateSingleCyclePrinciple()

        // BR004: 手动开始原则
        validateManualStartPrinciple()
    }

    private func validateSingleCyclePrinciple() {
        let path = "\(projectPath)/zoneclock/Controllers/StateManager.swift"
        guard let content = readFile(path) else { return }

        if content.contains("startFocusCycle") {
            if !content.contains("guard currentState == .ready") {
                addResult(
                    file: "StateManager.swift",
                    rule: "BR001: Single Cycle Principle",
                    message: "Must check for existing cycle before starting new one",
                    severity: .error
                )
            }
        }
    }

    private func validateManualStartPrinciple() {
        let path = "\(projectPath)/zoneclock/Controllers/TimerController.swift"
        guard let content = readFile(path) else { return }

        // 确保没有自动开始新周期的逻辑
        if content.contains("automaticallyStartNewCycle") ||
           content.contains("autoStart") {
            addResult(
                file: "TimerController.swift",
                rule: "BR004: Manual Start Principle",
                message: "New cycles must be manually started by user",
                severity: .error
            )
        }
    }

    // MARK: - View Validation
    private func validateViews() {
        let viewFiles = getFiles(in: "\(projectPath)/zoneclock/Views")

        // 检查必需的视图
        let requiredViews = ["MainView.swift", "SettingsView.swift", "StatisticsView.swift"]
        for requiredView in requiredViews {
            if !viewFiles.contains(requiredView) {
                addResult(
                    file: "Views",
                    rule: "Required Views",
                    message: "Missing required view: \(requiredView)",
                    severity: .error
                )
            }
        }
    }

    // MARK: - Helper Methods
    private func readFile(_ path: String) -> String? {
        return try? String(contentsOfFile: path, encoding: .utf8)
    }

    private func getFiles(in directory: String) -> [String] {
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: directory)
            return files.filter { $0.hasSuffix(".swift") }
        } catch {
            return []
        }
    }

    private func validateRange(in content: String, field: String, min: Int, max: Int) {
        if !content.contains("\(field) >= \(min)") {
            addResult(
                file: "Range Validation",
                rule: "Value Range",
                message: "\(field) minimum should be \(min)",
                severity: .warning
            )
        }
        if !content.contains("\(field) <= \(max)") {
            addResult(
                file: "Range Validation",
                rule: "Value Range",
                message: "\(field) maximum should be \(max)",
                severity: .warning
            )
        }
    }

    private func addResult(file: String, line: Int? = nil, rule: String,
                          message: String, severity: ValidationResult.Severity) {
        results.append(ValidationResult(
            file: file,
            line: line,
            rule: rule,
            message: message,
            severity: severity
        ))
    }

    // MARK: - Result Output
    private func printResults() {
        print("\n📊 Validation Results:")
        print("=" * 50)

        let errors = results.filter { $0.severity == .error }
        let warnings = results.filter { $0.severity == .warning }
        let infos = results.filter { $0.severity == .info }

        if results.isEmpty {
            print("✅ All contract validations passed!")
        } else {
            for result in results {
                var output = "\(result.severity.rawValue) [\(result.file)"
                if let line = result.line {
                    output += ":\(line)"
                }
                output += "] \(result.rule): \(result.message)"
                print(output)
            }
        }

        print("\n📈 Summary:")
        print("   Errors: \(errors.count)")
        print("   Warnings: \(warnings.count)")
        print("   Info: \(infos.count)")

        if !errors.isEmpty {
            print("\n❌ Validation failed with \(errors.count) error(s)")
            exit(1)
        } else if !warnings.isEmpty {
            print("\n⚠️ Validation passed with \(warnings.count) warning(s)")
        } else {
            print("\n✅ Perfect! No issues found.")
        }
    }
}

// MARK: - String Extension
extension String {
    func matches(pattern: String) -> Bool {
        return self.range(of: pattern, options: .regularExpression) != nil
    }

    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// MARK: - Main Execution
let arguments = CommandLine.arguments
let projectPath = arguments.count > 1 ? arguments[1] : "/Users/dajoe/joe_ai_lab/zoneclock_xcode/zoneclock"

let validator = ContractValidator(projectPath: projectPath)
validator.validate()