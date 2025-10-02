//
//  StatisticsView.swift
//  zoneclock
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Contract Version: 1.0.0
//

import SwiftUI
import Charts

/// 统计视图
struct StatisticsView: View {
    @State private var selectedTab = 0
    @State private var todayStats = DailyStatistics()
    @State private var weekStats: [DailyStatistics] = []
    @State private var trendData: (focusTimeImprovement: Float, completionRateImprovement: Float) = (0, 0)
    @State private var peakHours: [(hour: Int, productivity: Double)] = []
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                // 标签选择器
                Picker("统计类型", selection: $selectedTab) {
                    Text("今日").tag(0)
                    Text("过去7天").tag(1)
                    Text("趋势").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // 内容区域
                ScrollView {
                    switch selectedTab {
                    case 0:
                        todayStatisticsView
                    case 1:
                        weekStatisticsView
                    case 2:
                        trendAnalysisView
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle("统计")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
                #endif
            }
            .onAppear {
                loadStatistics()
            }
        }
    }

    // MARK: - Load Data

    private func loadStatistics() {
        todayStats = DataStore.shared.getTodayStatistics()
        weekStats = DataStore.shared.getWeekStatistics()
        trendData = DataStore.shared.get30DaysTrend()
        peakHours = DataStore.shared.getPeakFocusHours()
        print("📊 Loaded statistics - Today: \(todayStats.totalFocusTime)min")
    }

    // MARK: - Today Statistics
    private var todayStatisticsView: some View {
        VStack(spacing: 20) {
            // 总览卡片
            HStack(spacing: 16) {
                StatCard(
                    title: "专注时长",
                    value: "\(todayStats.totalFocusTime)",
                    unit: "分钟",
                    icon: "clock.fill",
                    color: .zenAccent
                )

                StatCard(
                    title: "完成周期",
                    value: "\(todayStats.completedCycles)",
                    unit: "个",
                    icon: "checkmark.circle.fill",
                    color: .zenPrimary
                )
            }
            .padding(.horizontal)

            HStack(spacing: 16) {
                StatCard(
                    title: "微休息",
                    value: "\(todayStats.microBreaksCount)",
                    unit: "次",
                    icon: "pause.circle.fill",
                    color: .zenSecondary
                )

                StatCard(
                    title: "完成率",
                    value: "\(Int(todayStats.completionRate * 100))",
                    unit: "%",
                    icon: "percent",
                    color: .zenProgress
                )
            }
            .padding(.horizontal)

            // 今日时间分布
            VStack(alignment: .leading, spacing: 12) {
                Text("时间分布")
                    .font(.zenSubheadline)
                    .foregroundColor(.zenPrimary)

                ProgressBar(
                    title: "专注",
                    value: Float(todayStats.totalFocusTime),
                    maxValue: 480,
                    color: .zenProgress
                )

                ProgressBar(
                    title: "休息",
                    value: Float(todayStats.totalBreakTime),
                    maxValue: 120,
                    color: .zenAccent
                )
            }
            .padding()
            .background(Color.zenCardBackground)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    // MARK: - Week Statistics
    private var weekStatisticsView: some View {
        VStack(spacing: 20) {
            // 过去7天专注时长图表
            VStack(alignment: .leading, spacing: 12) {
                Text("过去7天专注时长")
                    .font(.zenSubheadline)
                    .foregroundColor(.zenPrimary)

                // 简单的柱状图
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(0..<min(7, weekData.count), id: \.self) { day in
                        VStack {
                            Text("\(weekData[day])")
                                .font(.zenCaption)
                                .foregroundColor(.zenSecondary)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.zenProgress)
                                .frame(width: 40, height: max(4, CGFloat(weekData[day]) * 2))

                            Text(weekDayLabel(day))
                                .font(.zenCaption)
                                .foregroundColor(.zenSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.zenCardBackground)
                .cornerRadius(12)
            }
            .padding(.horizontal)

            // 过去7天总结
            VStack(spacing: 16) {
                HStack {
                    Text("7天总计")
                        .font(.zenSubheadline)
                        .foregroundColor(.zenPrimary)
                    Spacer()
                    Text("\(weekData.reduce(0, +)) 分钟")
                        .font(.zenNumberSmall)
                        .foregroundColor(.zenPrimary)
                }

                HStack {
                    Text("日均专注")
                        .font(.zenBody)
                        .foregroundColor(.zenSecondary)
                    Spacer()
                    let avg = weekData.isEmpty ? 0 : weekData.reduce(0, +) / weekData.count
                    Text("\(avg) 分钟")
                        .font(.zenBody)
                        .foregroundColor(.zenSecondary)
                }

                HStack {
                    Text("最高记录")
                        .font(.zenBody)
                        .foregroundColor(.zenSecondary)
                    Spacer()
                    Text("\(weekData.max() ?? 0) 分钟")
                        .font(.zenBody)
                        .foregroundColor(.zenPrimary)
                }
            }
            .padding()
            .background(Color.zenCardBackground)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    // MARK: - Trend Analysis
    private var trendAnalysisView: some View {
        VStack(spacing: 20) {
            // 趋势指标
            VStack(alignment: .leading, spacing: 16) {
                Text("30天趋势")
                    .font(.zenSubheadline)
                    .foregroundColor(.zenPrimary)

                if trendData.focusTimeImprovement != 0 || trendData.completionRateImprovement != 0 {
                    // 专注时长趋势
                    HStack {
                        Image(systemName: trendData.focusTimeImprovement >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.zenCaption)
                            .foregroundColor(trendData.focusTimeImprovement >= 0 ? .zenPrimary : .zenSecondary)
                        Text("专注时长\(trendData.focusTimeImprovement >= 0 ? "提升" : "下降") \(abs(Int(trendData.focusTimeImprovement * 100)))%")
                            .font(.zenBody)
                            .foregroundColor(trendData.focusTimeImprovement >= 0 ? .zenPrimary : .zenSecondary)
                    }

                    // 完成率趋势
                    HStack {
                        Image(systemName: trendData.completionRateImprovement >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.zenCaption)
                            .foregroundColor(trendData.completionRateImprovement >= 0 ? .zenPrimary : .zenSecondary)
                        Text("完成率\(trendData.completionRateImprovement >= 0 ? "提升" : "下降") \(abs(Int(trendData.completionRateImprovement * 100)))%")
                            .font(.zenBody)
                            .foregroundColor(trendData.completionRateImprovement >= 0 ? .zenPrimary : .zenSecondary)
                    }

                    Text(trendData.focusTimeImprovement >= 0 && trendData.completionRateImprovement >= 0 ? "您的专注力正在稳步提升！" : "继续努力，保持专注！")
                        .font(.zenCaption)
                        .foregroundColor(.zenTertiary)
                } else {
                    Text("暂无足够数据分析趋势")
                        .font(.zenBody)
                        .foregroundColor(.zenSecondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.zenCardBackground)
            .cornerRadius(12)
            .padding(.horizontal)

            // 最佳专注时段
            VStack(alignment: .leading, spacing: 12) {
                Text("最佳专注时段")
                    .font(.zenSubheadline)
                    .foregroundColor(.zenPrimary)

                if peakHours.isEmpty {
                    Text("暂无数据")
                        .font(.zenBody)
                        .foregroundColor(.zenSecondary)
                } else {
                    ForEach(peakHours, id: \.hour) { item in
                        HStack {
                            Text("\(item.hour):00 - \(item.hour + 1):00")
                                .font(.zenBody)
                                .foregroundColor(.zenPrimary)
                            Spacer()
                            ProgressView(value: item.productivity)
                                .tint(.zenProgress)
                                .frame(width: 150)
                            Text("\(Int(item.productivity * 100))%")
                                .font(.zenCaption)
                                .foregroundColor(.zenSecondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color.zenCardBackground)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    // MARK: - Helper Data
    private var weekData: [Int] {
        // 从真实数据获取每天的专注时长
        return weekStats.map { $0.totalFocusTime }
    }

    private func weekDayLabel(_ index: Int) -> String {
        // 从今天往前推index天
        let calendar = Calendar.current
        guard let date = calendar.date(byAdding: .day, value: -(6 - index), to: Date()) else {
            return ""
        }

        // 格式化为"周X"或"今天"
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let weekday = calendar.component(.weekday, from: date)
            let days = ["日", "一", "二", "三", "四", "五", "六"]
            return "周\(days[weekday - 1])"
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.zenCaption)
                    .foregroundColor(color)
                Spacer()
            }

            Text(title)
                .font(.zenCaption)
                .foregroundColor(.zenSecondary)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.zenNumberSmall)
                Text(unit)
                    .font(.zenCaption)
                    .foregroundColor(.zenSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Progress Bar Component
struct ProgressBar: View {
    let title: String
    let value: Float
    let maxValue: Float
    let color: Color

    var progress: Float {
        min(1.0, value / maxValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.zenBody)
                    .foregroundColor(.zenPrimary)
                Spacer()
                Text("\(Int(value)) / \(Int(maxValue))")
                    .font(.zenCaption)
                    .foregroundColor(.zenSecondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.zenProgressBackground)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Preview
struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
    }
}