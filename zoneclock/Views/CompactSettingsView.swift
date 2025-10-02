//
//  CompactSettingsView.swift
//  zoneclock
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Compact macOS settings view
//

import SwiftUI

/// macOS 紧凑设置视图
struct CompactSettingsView: View {
    @StateObject private var stateManager = StateManager.shared
    @State private var settings: Settings = Settings.load()
    @State private var showValidationError = false
    @State private var validationErrors: [String] = []
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("设置")
                    .font(.zenHeadline)
                    .foregroundColor(.zenPrimary)

                Spacer()

                Button("完成") {
                    saveSettings()
                }
                .font(.zenBody)
                .foregroundColor(.zenPrimary)
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color.zenBackground)

            Divider()

            // 设置内容
            ScrollView {
                VStack(spacing: 20) {
                    // 专注设置
                    VStack(alignment: .leading, spacing: 12) {
                        Text("专注设置")
                            .font(.zenSubheadline)
                            .foregroundColor(.zenSecondary)

                        VStack(spacing: 12) {
                            HStack {
                                Text("专注时长")
                                    .font(.zenBody)
                                    .foregroundColor(.zenPrimary)
                                    .frame(width: 80, alignment: .leading)
                                Slider(value: Binding(
                                    get: { Double(settings.focusDuration) },
                                    set: { settings.focusDuration = Int($0) }
                                ), in: 15...180, step: 5)
                                .tint(.zenProgress)
                                Text("\(settings.focusDuration) 分钟")
                                    .font(.zenCaption)
                                    .frame(width: 70, alignment: .trailing)
                                    .foregroundColor(.zenSecondary)
                            }

                            HStack {
                                Text("休息时长")
                                    .font(.zenBody)
                                    .foregroundColor(.zenPrimary)
                                    .frame(width: 80, alignment: .leading)
                                Slider(value: Binding(
                                    get: { Double(settings.breakDuration) },
                                    set: { settings.breakDuration = Int($0) }
                                ), in: 5...60, step: 5)
                                .tint(.zenProgress)
                                Text("\(settings.breakDuration) 分钟")
                                    .font(.zenCaption)
                                    .frame(width: 70, alignment: .trailing)
                                    .foregroundColor(.zenSecondary)
                            }
                        }
                        .zenCard()
                    }

                    // 提示音设置
                    VStack(alignment: .leading, spacing: 12) {
                        Text("提示音")
                            .font(.zenSubheadline)
                            .foregroundColor(.zenSecondary)

                        VStack(spacing: 12) {
                            HStack {
                                Text("音效类型")
                                    .font(.zenBody)
                                    .foregroundColor(.zenPrimary)
                                    .frame(width: 80, alignment: .leading)
                                Picker("", selection: $settings.soundSettings.soundType) {
                                    ForEach(SoundType.allCases, id: \.self) { sound in
                                        Text(sound.displayName).tag(sound)
                                    }
                                }
                                .labelsHidden()
                                .onChange(of: settings.soundSettings.soundType) { _, newValue in
                                    print("🔄 Sound type changed to: \(newValue.displayName) (\(newValue.fileName))")
                                    settings.save()
                                }

                                Spacer()

                                // 播放试听按钮
                                Button(action: {
                                    AudioPlayer.shared.playMicroBreakSound()
                                }) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.zenBody)
                                        .foregroundColor(.zenAccent)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            HStack {
                                Text("音量")
                                    .font(.zenBody)
                                    .foregroundColor(.zenPrimary)
                                    .frame(width: 80, alignment: .leading)
                                Slider(value: $settings.soundSettings.volume, in: 0...1)
                                    .tint(.zenProgress)
                                Text("\(Int(settings.soundSettings.volume * 100))%")
                                    .font(.zenCaption)
                                    .frame(width: 70, alignment: .trailing)
                                    .foregroundColor(.zenSecondary)
                            }

                            Toggle("振动提醒", isOn: $settings.soundSettings.vibrationEnabled)
                                .font(.zenBody)
                                .tint(.zenProgress)
                        }
                        .zenCard()
                    }

                    // 通知设置
                    VStack(alignment: .leading, spacing: 12) {
                        Text("通知")
                            .font(.zenSubheadline)
                            .foregroundColor(.zenSecondary)

                        VStack(spacing: 12) {
                            Toggle("启用通知", isOn: $settings.notificationEnabled)
                                .font(.zenBody)
                                .tint(.zenProgress)
                            Toggle("勿扰模式", isOn: $settings.dndEnabled)
                                .font(.zenBody)
                                .tint(.zenProgress)
                        }
                        .zenCard()
                    }

                    // 外观设置（暂未启用）
                    VStack(alignment: .leading, spacing: 12) {
                        Text("外观")
                            .font(.zenSubheadline)
                            .foregroundColor(.zenSecondary)

                        VStack(spacing: 12) {
                            HStack {
                                Text("主题")
                                    .font(.zenBody)
                                    .foregroundColor(.zenPrimary)
                                    .frame(width: 80, alignment: .leading)
                                Picker("", selection: $settings.theme) {
                                    ForEach(Theme.allCases, id: \.self) { theme in
                                        Text(theme.displayName).tag(theme)
                                    }
                                }
                                .labelsHidden()
                                .disabled(true)
                                Text("即将推出")
                                    .font(.zenCaption)
                                    .foregroundColor(.zenTertiary)
                            }
                        }
                        .zenCard()
                        .opacity(0.6)
                    }
                }
                .padding()
            }
        }
        .frame(width: 450, height: 550)
        .alert("验证错误", isPresented: $showValidationError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(validationErrors.joined(separator: "\n"))
        }
    }

    private func saveSettings() {
        let validation = settings.validate()
        if validation.isValid {
            settings.save()
            _ = stateManager.updateSettings(settings)
            dismiss()
        } else {
            validationErrors = validation.errors
            showValidationError = true
        }
    }
}

// MARK: - Preview
struct CompactSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        CompactSettingsView()
    }
}
