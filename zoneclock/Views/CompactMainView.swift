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
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if stateManager.isDNDEnabled {
                    Image(systemName: "moon.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
            .padding(.horizontal)

            // 主计时器显示
            if timerController.currentPhase == .microBreak {
                // 微休息模式
                VStack(spacing: 8) {
                    Text("微休息")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Text("\(timerController.getMicroBreakCountdown())")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)

                    Text("秒")
                        .font(.caption)
                        .foregroundColor(.orange.opacity(0.8))
                }
                .padding(.vertical, 8)
            } else {
                // 普通计时模式
                VStack(spacing: 4) {
                    Text(phaseTitle)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(timerController.formattedRemainingTime())
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    if timerController.currentPhase == .focusing {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.orange)
                            Text("已专注 \(timerController.formattedElapsedTime())")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            // 进度环（小尺寸）
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(timerController.getProgress()))
                    .stroke(
                        progressColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.linear, value: timerController.getProgress())

                if let cycle = stateManager.currentCycle {
                    VStack(spacing: 4) {
                        Text("第 \(cycle.microBreaks + 1) 轮")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)

                        Text("\(Int(cycle.completionRate * 100))%")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .padding(.vertical, 8)

            // 控制按钮（精简）
            HStack(spacing: 16) {
                if stateManager.currentState == .ready {
                    Button(action: startFocus) {
                        Image(systemName: "play.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if stateManager.currentState == .focusing {
                    if let cycle = stateManager.currentCycle {
                        if cycle.status == .active {
                            Button(action: pauseFocus) {
                                Image(systemName: "pause.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Button(action: resumeFocus) {
                                Image(systemName: "play.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.green)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        Button(action: stopFocus) {
                            Image(systemName: "stop.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else if stateManager.currentState == .resting {
                    Button(action: skipBreak) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.purple)
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
                            .font(.caption)
                        Text("统计")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: { showSettings = true }) {
                    VStack(spacing: 2) {
                        Image(systemName: "gearshape.fill")
                            .font(.caption)
                        Text("设置")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: toggleDND) {
                    VStack(spacing: 2) {
                        Image(systemName: stateManager.isDNDEnabled ? "moon.fill" : "moon")
                            .font(.caption)
                        Text("勿扰")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(stateManager.isDNDEnabled ? .purple : .primary)
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
            return .gray
        case .ready:
            return .green
        case .focusing:
            if timerController.currentPhase == .microBreak {
                return .orange
            }
            return stateManager.currentCycle?.status == .paused ? .yellow : .blue
        case .resting:
            return .purple
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
        switch timerController.currentPhase {
        case .focusing:
            return LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .longBreak:
            return LinearGradient(
                gradient: Gradient(colors: [Color.purple, Color.pink]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                gradient: Gradient(colors: [Color.orange, Color.red]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
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
