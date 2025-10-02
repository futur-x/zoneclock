//
//  CompactMainView.swift
//  zoneclock
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Compact macOS widget-style view
//

import SwiftUI

/// macOS 紧凑主视图 - 小窗口 widget 风格
struct CompactMainView: View {
    @StateObject private var stateManager = StateManager.shared
    @StateObject private var timerController = TimerController.shared
    @State private var showSettings = false
    @State private var showStatistics = false
    @State private var showOnboarding = false

    var body: some View {
        VStack(spacing: 16) {
            // 顶部状态
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(statusText)
                    .font(.zenCaption)
                    .foregroundColor(.zenSecondary)

                Spacer()

                if stateManager.isDNDEnabled {
                    Image(systemName: "moon.fill")
                        .font(.zenCaption)
                        .foregroundColor(.zenAccent)
                }
            }
            .padding(.horizontal)

            // 主计时器显示
            if timerController.currentPhase == .microBreak {
                // 微休息模式
                VStack(spacing: 8) {
                    Text("微休息")
                        .font(.zenCaption)
                        .foregroundColor(.zenSecondary)

                    Text("\(timerController.getMicroBreakCountdown())")
                        .font(.zenNumber)
                        .foregroundColor(.zenPrimary)

                    Text("秒")
                        .font(.zenCaption)
                        .foregroundColor(.zenTertiary)
                }
                .padding(.vertical, 8)
            } else {
                // 普通计时模式
                VStack(spacing: 4) {
                    Text(phaseTitle)
                        .font(.zenCaption)
                        .foregroundColor(.zenSecondary)

                    Text(timerController.formattedRemainingTime())
                        .font(.zenNumber)
                        .foregroundColor(.zenPrimary)

                    if timerController.currentPhase == .focusing {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.zenTertiary)
                            Text("已专注 \(timerController.formattedElapsedTime())")
                                .font(.zenCaption)
                                .foregroundColor(.zenSecondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            // 进度环（小尺寸）
            ZStack {
                Circle()
                    .stroke(Color.zenProgressBackground, lineWidth: 6)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(timerController.getProgress()))
                    .stroke(
                        Color.zenProgress,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.linear, value: timerController.getProgress())

                if let cycle = stateManager.currentCycle {
                    VStack(spacing: 4) {
                        Text("第 \(cycle.microBreaks + 1) 轮")
                            .font(.zenCaption)
                            .foregroundColor(.zenTertiary)

                        Text("\(Int(cycle.completionRate * 100))%")
                            .font(.zenNumberSmall)
                            .foregroundColor(.zenPrimary)
                    }
                }
            }
            .padding(.vertical, 8)

            // 控制按钮（精简）
            HStack(spacing: 16) {
                if stateManager.currentState == .ready {
                    Button(action: startFocus) {
                        Image(systemName: "play.fill")
                            .font(.zenBody)
                            .foregroundColor(.zenBackground)
                            .frame(width: 50, height: 50)
                            .background(Color.zenAccent)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if stateManager.currentState == .focusing {
                    if let cycle = stateManager.currentCycle {
                        if cycle.status == .active {
                            Button(action: pauseFocus) {
                                Image(systemName: "pause.fill")
                                    .font(.zenBody)
                                    .foregroundColor(.zenBackground)
                                    .frame(width: 44, height: 44)
                                    .background(Color.zenAccent)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Button(action: resumeFocus) {
                                Image(systemName: "play.fill")
                                    .font(.zenBody)
                                    .foregroundColor(.zenBackground)
                                    .frame(width: 44, height: 44)
                                    .background(Color.zenAccent)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        Button(action: stopFocus) {
                            Image(systemName: "stop.fill")
                                .font(.zenBody)
                                .foregroundColor(.zenBackground)
                                .frame(width: 44, height: 44)
                                .background(Color.zenPrimary)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else if stateManager.currentState == .resting {
                    Button(action: skipBreak) {
                        Image(systemName: "forward.fill")
                            .font(.zenBody)
                            .foregroundColor(.zenBackground)
                            .frame(width: 50, height: 50)
                            .background(Color.zenAccent)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 4)

            Divider()
                .padding(.horizontal)

            // 底部工具栏（紧凑）
            HStack(spacing: 24) {
                Button(action: { showStatistics = true }) {
                    VStack(spacing: 2) {
                        Image(systemName: "chart.bar.fill")
                            .font(.zenCaption)
                        Text("统计")
                            .font(.zenCaption)
                    }
                    .foregroundColor(.zenPrimary)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: { showSettings = true }) {
                    VStack(spacing: 2) {
                        Image(systemName: "gearshape.fill")
                            .font(.zenCaption)
                        Text("设置")
                            .font(.zenCaption)
                    }
                    .foregroundColor(.zenPrimary)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: toggleDND) {
                    VStack(spacing: 2) {
                        Image(systemName: stateManager.isDNDEnabled ? "moon.fill" : "moon")
                            .font(.zenCaption)
                        Text("勿扰")
                            .font(.zenCaption)
                    }
                    .foregroundColor(stateManager.isDNDEnabled ? .zenAccent : .zenPrimary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 8)
        }
        .padding(.vertical, 12)
        .frame(width: 280)
        #if os(macOS)
        .background(Color(NSColor.windowBackgroundColor))
        #else
        .background(Color(UIColor.systemBackground))
        #endif
        .onAppear {
            checkOnboarding()
        }
        .sheet(isPresented: $showSettings) {
            CompactSettingsView()
        }
        .sheet(isPresented: $showStatistics) {
            CompactStatisticsView()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
                .frame(width: 600, height: 700)
        }
    }

    // MARK: - Computed Properties

    private var statusText: String {
        switch stateManager.currentState {
        case .uninitialized:
            return "未初始化"
        case .ready:
            return "就绪"
        case .focusing:
            if let cycle = stateManager.currentCycle {
                switch cycle.status {
                case .active:
                    return timerController.currentPhase == .microBreak ? "微休息中" : "专注中"
                case .paused:
                    return "已暂停"
                default:
                    return "专注中"
                }
            }
            return "专注中"
        case .resting:
            return "大休息中"
        }
    }

    private var statusColor: Color {
        switch stateManager.currentState {
        case .uninitialized:
            return .zenDisabled
        case .ready:
            return .zenSecondary
        case .focusing:
            if timerController.currentPhase == .microBreak {
                return .zenTertiary
            }
            return stateManager.currentCycle?.status == .paused ? .zenDisabled : .zenAccent
        case .resting:
            return .zenPrimary
        }
    }

    private var phaseTitle: String {
        switch timerController.currentPhase {
        case .idle:
            return "准备开始"
        case .focusing:
            return "专注时间"
        case .microBreak:
            return "微休息"
        case .longBreak:
            return "大休息"
        }
    }

    private var progressColor: Color {
        return .zenProgress
    }

    // MARK: - Actions

    private func checkOnboarding() {
        if stateManager.currentState == .uninitialized {
            showOnboarding = true
        }
    }

    private func startFocus() {
        let result = stateManager.startFocusCycle()
        if case .success = result {
            timerController.startFocusCycle()
        }
    }

    private func pauseFocus() {
        _ = stateManager.pauseCycle()
        timerController.pauseTimer()
    }

    private func resumeFocus() {
        _ = stateManager.resumeCycle()
        timerController.resumeTimer()
    }

    private func stopFocus() {
        _ = stateManager.stopCycle()
        timerController.stopTimer()
    }

    private func skipBreak() {
        _ = stateManager.skipBreak()
        timerController.stopTimer()
    }

    private func toggleDND() {
        stateManager.toggleDND(!stateManager.isDNDEnabled)
    }
}

// MARK: - Preview
struct CompactMainView_Previews: PreviewProvider {
    static var previews: some View {
        CompactMainView()
            .frame(width: 280, height: 500)
    }
}
