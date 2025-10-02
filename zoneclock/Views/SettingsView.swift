//
//  SettingsView.swift
//  zoneclock
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Contract Version: 1.0.0
//

import SwiftUI

/// 设置视图
struct SettingsView: View {
    @StateObject private var stateManager = StateManager.shared
    @State private var settings: Settings = Settings.load()
    @State private var showValidationError = false
    @State private var validationErrors: [String] = []
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                // 专注设置
                Section(header: Text("专注设置").font(.zenCaption).foregroundColor(.zenSecondary)) {
                    HStack {
                        Text("专注时长")
                            .font(.zenBody)
                            .foregroundColor(.zenPrimary)
                        Spacer()
                        Text("\(settings.focusDuration) 分钟")
                            .font(.zenBody)
                            .foregroundColor(.zenSecondary)
                    }
                    Slider(value: Binding(
                        get: { Double(settings.focusDuration) },
                        set: { settings.focusDuration = Int($0) }
                    ), in: 15...180, step: 5)
                        .tint(.zenProgress)

                    HStack {
                        Text("休息时长")
                            .font(.zenBody)
                            .foregroundColor(.zenPrimary)
                        Spacer()
                        Text("\(settings.breakDuration) 分钟")
                            .font(.zenBody)
                            .foregroundColor(.zenSecondary)
                    }
                    Slider(value: Binding(
                        get: { Double(settings.breakDuration) },
                        set: { settings.breakDuration = Int($0) }
                    ), in: 5...60, step: 5)
                        .tint(.zenProgress)
                }

                // 提示音设置
                Section(header: Text("提示音").font(.zenCaption).foregroundColor(.zenSecondary)) {
                    Picker("音效类型", selection: $settings.soundSettings.soundType) {
                        ForEach(SoundType.allCases, id: \.self) { sound in
                            Text(sound.displayName).tag(sound)
                        }
                    }
                    .onChange(of: settings.soundSettings.soundType) { _, newValue in
                        print("🔄 Sound type changed to: \(newValue.displayName) (\(newValue.fileName))")
                        settings.save()
                    }

                    // 播放试听按钮
                    Button(action: {
                        AudioPlayer.shared.playMicroBreakSound()
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.zenCaption)
                            Text("试听")
                                .font(.zenBody)
                        }
                        .foregroundColor(.zenPrimary)
                    }

                    HStack {
                        Text("音量")
                            .font(.zenBody)
                            .foregroundColor(.zenPrimary)
                        Slider(value: $settings.soundSettings.volume, in: 0...1)
                            .tint(.zenProgress)
                    }

                    Toggle("振动提醒", isOn: $settings.soundSettings.vibrationEnabled)
                        .font(.zenBody)
                        .foregroundColor(.zenPrimary)
                }

                // 通知设置
                Section(header: Text("通知").font(.zenCaption).foregroundColor(.zenSecondary)) {
                    Toggle("启用通知", isOn: $settings.notificationEnabled)
                        .font(.zenBody)
                        .foregroundColor(.zenPrimary)
                    Toggle("勿扰模式", isOn: $settings.dndEnabled)
                        .font(.zenBody)
                        .foregroundColor(.zenPrimary)
                }

                // 外观设置
                Section(header: Text("外观").font(.zenCaption).foregroundColor(.zenSecondary)) {
                    Picker("主题", selection: $settings.theme) {
                        ForEach(Theme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                }
            }
            .navigationTitle("设置")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveSettings()
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveSettings()
                    }
                }
                #endif
            }
            .alert("验证错误", isPresented: $showValidationError) {
                ForEach(validationErrors, id: \.self) { error in
                    Text(error)
                }
            } message: {
                Text(validationErrors.joined(separator: "\n"))
            }
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
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}