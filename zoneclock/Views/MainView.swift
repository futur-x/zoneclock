//
//  MainView.swift
//  zoneclock
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Contract Version: 1.0.0
//

import SwiftUI

/// 主界面视图 - 显示倒计时和控制按钮
struct MainView: View {
    @StateObject private var stateManager = StateManager.shared
    @StateObject private var timerController = TimerController.shared
    @State private var showSettings = false
    @State private var showStatistics = false
    @State private var showOnboarding = false

    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                Color.zenBackground
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    // 顶部状态栏
                    topStatusBar

                    Spacer()

                    // 主计时器显示
                    timerDisplay

                    // 进度环
                    progressRing

                    // 控制按钮
                    controlButtons

                    Spacer()

                    // 底部快捷操作
                    bottomActions
                }
                .padding()
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            #if os(macOS)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    EmptyView()
                }
            }
            #endif
            .onAppear {
                checkOnboarding()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showStatistics) {
                StatisticsView()
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
        }
    }

    // MARK: - View Components

    /// 顶部状态栏
    private var topStatusBar: some View {
        HStack {
            // 状态指示器
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)

                Text(statusText)
                    .font(.zenCaption)
                    .foregroundColor(.zenSecondary)
            }

            Spacer()

            // 勿扰模式图标
            if stateManager.isDNDEnabled {
                Image(systemName: "moon.fill")
                    .font(.zenCaption)
                    .foregroundColor(.zenAccent)
            }
        }
    }

    /// 计时器显示
    private var timerDisplay: some View {
        VStack(spacing: 8) {
            if timerController.currentPhase == .microBreak {
                // 微休息倒计时
                Text("微休息")
                    .font(.zenSubheadline)
                    .foregroundColor(.zenSecondary)

                Text("\(timerController.getMicroBreakCountdown())")
                    .font(.zenNumber)
                    .foregroundColor(.zenPrimary)

                Text("秒")
                    .font(.zenCaption)
                    .foregroundColor(.zenTertiary)
            } else {
                // 主计时器
                Text(phaseTitle)
                    .font(.zenSubheadline)
                    .foregroundColor(.zenSecondary)

                Text(timerController.formattedRemainingTime())
                    .font(.system(size: 72, weight: .ultraLight, design: .rounded))
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
        }
    }

    /// 进度环
    private var progressRing: some View {
        ZStack {
            // 背景环
            Circle()
                .stroke(Color.zenProgressBackground, lineWidth: 12)
                .frame(width: 240, height: 240)

            // 进度环
            Circle()
                .trim(from: 0, to: CGFloat(timerController.getProgress()))
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 240, height: 240)
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear, value: timerController.getProgress())

            // 中心内容
            VStack(spacing: 8) {
                if let cycle = stateManager.currentCycle {
                    Text("第 \(cycle.microBreaks + 1) 轮")
                        .font(.zenCaption)
                        .foregroundColor(.zenTertiary)

                    Text("\(Int(cycle.completionRate * 100))%")
                        .font(.zenNumberSmall)
                        .foregroundColor(.zenPrimary)
                }
            }
        }
    }

    /// 控制按钮
    private var controlButtons: some View {
        HStack(spacing: 30) {
            if stateManager.currentState == .ready {
                // 开始按钮
                Button(action: startFocus) {
                    Label("开始专注", systemImage: "play.fill")
                        .font(.zenBody)
                        .foregroundColor(.zenBackground)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(Color.zenAccent)
                        .cornerRadius(30)
                }
            } else if stateManager.currentState == .focusing {
                if let cycle = stateManager.currentCycle {
                    if cycle.status == .active {
                        // 暂停按钮
                        Button(action: pauseFocus) {
                            Image(systemName: "pause.fill")
                                .font(.zenBody)
                                .foregroundColor(.zenPrimary)
                                .frame(width: 60, height: 60)
                                .background(Color.zenPrimary.opacity(0.1))
                                .clipShape(Circle())
                        }
                    } else {
                        // 恢复按钮
                        Button(action: resumeFocus) {
                            Image(systemName: "play.fill")
                                .font(.zenBody)
                                .foregroundColor(.zenPrimary)
                                .frame(width: 60, height: 60)
                                .background(Color.zenPrimary.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }

                    // 停止按钮
                    Button(action: stopFocus) {
                        Image(systemName: "stop.fill")
                            .font(.zenBody)
                            .foregroundColor(.zenPrimary)
                            .frame(width: 60, height: 60)
                            .background(Color.zenPrimary.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            } else if stateManager.currentState == .resting {
                // 跳过休息按钮
                Button(action: skipBreak) {
                    Label("跳过休息", systemImage: "forward.fill")
                        .font(.zenBody)
                        .foregroundColor(.zenBackground)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 16)
                        .background(Color.zenAccent)
                        .cornerRadius(30)
                }
            }
        }
    }

    /// 底部快捷操作
    private var bottomActions: some View {
        HStack(spacing: 40) {
            // 统计按钮
            Button(action: { showStatistics = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.zenBody)
                    Text("统计")
                        .font(.zenCaption)
                }
            }
            .foregroundColor(.zenPrimary)

            // 设置按钮
            Button(action: { showSettings = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "gearshape.fill")
                        .font(.zenBody)
                    Text("设置")
                        .font(.zenCaption)
                }
            }
            .foregroundColor(.zenPrimary)

            // 勿扰模式切换
            Button(action: toggleDND) {
                VStack(spacing: 4) {
                    Image(systemName: stateManager.isDNDEnabled ? "moon.fill" : "moon")
                        .font(.zenBody)
                    Text("勿扰")
                        .font(.zenCaption)
                }
            }
            .foregroundColor(stateManager.isDNDEnabled ? .zenAccent : .zenPrimary)
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

    private var progressColor: LinearGradient {
        return LinearGradient(
            gradient: Gradient(colors: [Color.zenProgress, Color.zenProgress]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}