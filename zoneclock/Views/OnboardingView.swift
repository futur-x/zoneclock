//
//  OnboardingView.swift
//  zoneclock
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Contract Version: 1.0.0
//

import SwiftUI

/// 引导视图
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @StateObject private var stateManager = StateManager.shared

    var body: some View {
        VStack {
            // 页面指示器
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(currentPage == index ? Color.zenPrimary : Color.zenDisabled)
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.top)

            // 页面内容
            TabView(selection: $currentPage) {
                welcomePage
                    .tag(0)

                featuresPage
                    .tag(1)

                permissionPage
                    .tag(2)
            }
            #if os(iOS)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            #endif

            // 底部按钮
            HStack {
                if currentPage > 0 {
                    Button("上一步") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .font(.zenBody)
                    .foregroundColor(.zenSecondary)
                }

                Spacer()

                if currentPage < 2 {
                    Button("下一步") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .font(.zenBody)
                    .foregroundColor(.zenPrimary)
                } else {
                    Button("开始使用") {
                        completeOnboarding()
                    }
                    .font(.zenBody)
                    .foregroundColor(.zenBackground)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.zenAccent)
                    .cornerRadius(25)
                }
            }
            .padding()
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 100))
                .foregroundColor(.zenPrimary)

            VStack(spacing: 12) {
                Text("欢迎使用 Zone Clock")
                    .font(.zenTitle)
                    .foregroundColor(.zenPrimary)

                Text("您的专注力管理助手")
                    .font(.zenSubheadline)
                    .foregroundColor(.zenSecondary)
            }

            Text("通过科学的时间管理方法\n帮助您保持高效专注")
                .font(.zenBody)
                .multilineTextAlignment(.center)
                .foregroundColor(.zenSecondary)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    private var featuresPage: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("核心功能")
                .font(.zenTitle)
                .foregroundColor(.zenPrimary)

            VStack(alignment: .leading, spacing: 24) {
                FeatureRow(
                    icon: "timer",
                    title: "90分钟专注周期",
                    description: "基于大脑注意力规律的最佳专注时长"
                )

                FeatureRow(
                    icon: "sparkles",
                    title: "随机微休息",
                    description: "2-5分钟随机触发，10秒微休息保持专注力"
                )

                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "数据统计",
                    description: "追踪您的专注习惯，持续优化效率"
                )

                FeatureRow(
                    icon: "icloud.and.arrow.up.down",
                    title: "跨设备同步",
                    description: "通过iCloud在所有设备上同步数据"
                )
            }
            .padding(.horizontal, 30)

            Spacer()
        }
    }

    private var permissionPage: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundColor(.zenPrimary)

            Text("启用通知")
                .font(.zenTitle)
                .foregroundColor(.zenPrimary)

            Text("我们需要通知权限来提醒您：")
                .font(.zenBody)
                .foregroundColor(.zenSecondary)

            VStack(alignment: .leading, spacing: 16) {
                Label("微休息提醒", systemImage: "pause.circle")
                Label("专注周期完成", systemImage: "checkmark.circle")
                Label("休息结束提醒", systemImage: "arrow.clockwise")
            }
            .font(.zenBody)
            .foregroundColor(.zenPrimary)
            .padding(.horizontal, 60)

            Button(action: requestNotificationPermission) {
                Label("允许通知", systemImage: "bell")
                    .font(.zenBody)
                    .foregroundColor(.zenBackground)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Color.zenAccent)
                    .cornerRadius(25)
            }

            Button("稍后设置") {
                completeOnboarding()
            }
            .font(.zenBody)
            .foregroundColor(.zenSecondary)

            Spacer()
        }
    }

    // MARK: - Actions

    private func requestNotificationPermission() {
        NotificationManager.shared.requestNotificationPermission { _ in
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        stateManager.completeOnboarding()
        isPresented = false
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.zenBody)
                .foregroundColor(.zenPrimary)
                .frame(width: 44, height: 44)
                .background(Color.zenPrimary.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.zenSubheadline)
                    .foregroundColor(.zenPrimary)

                Text(description)
                    .font(.zenCaption)
                    .foregroundColor(.zenSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isPresented: .constant(true))
    }
}