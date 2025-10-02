//
//  CompactStatisticsView.swift
//  zoneclock
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Compact macOS statistics view
//

import SwiftUI

/// macOS 紧凑统计视图
struct CompactStatisticsView: View {
    @State private var selectedTab = 0
    @State private var todayStats = DailyStatistics()
    @State private var weekStats: [DailyStatistics] = []
    @State private var trendData: (focusTimeImprovement: Float, completionRateImprovement: Float) = (0, 0)
    @State private var peakHours: [(hour: Int, productivity: Double)] = []
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("统计")
                    .font(.zenHeadline)
                    .foregroundColor(.zenPrimary)

                Spacer()

                Button("完成") {
                    dismiss()
                }
                .zenButton()
            }
            .padding()
            .background(Color.zenBackground)

            Divider()

            // 标签选择器
            Picker("统计类型", selection: $selectedTab) {
                Text("今日").tag(0)
                Text("过去7天").tag(1)
                Text("趋势").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Divider()

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
        .frame(width: 500, height: 600)
        .onAppear {
            loadStatistics()
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
        VStack(spacing: 16) {
            // 总览卡片 - 2x2 网格
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    CompactStatCard(
                        title: "专注时长",
                        value: "\(todayStats.totalFocusTime)",
                        unit: "分钟",
                        icon: "clock.fill",
                        color: .zenAccent
                    )

                    CompactStatCard(
                        title: "完成周期",
                        value: "\(todayStats.completedCycles)",
                        unit: "个",
                        icon: "checkmark.circle.fill",
                        color: .zenPrimary
                    )
                }

                HStack(spacing: 12) {
                    CompactStatCard(
                        title: "微休息",
                        value: "\(todayStats.microBreaksCount)",
                        unit: "次",
                        icon: "pause.circle.fill",
                        color: .zenSecondary
                    )

                    CompactStatCard(
                        title: "完成率",
                        value: "\(Int(todayStats.completionRate * 100))",
                        unit: "%",
                        icon: "percent",
                        color: .zenProgress
                    )
                }
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
        .padding(.vertical)
    }

    // MARK: - Week Statistics
    private var weekStatisticsView: some View {
        VStack(spacing: 16) {
            // 过去7天专注时长图表
            VStack(alignment: .leading, spacing: 12) {
                Text("过去7天专注时长")
                    .font(.zenSubheadline)
                    .foregroundColor(.zenPrimary)

                // 简单的柱状图
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(0..<min(7, weekData.count), id: \.self) { day in
                        VStack(spacing: 4) {
                            Text("\(weekData[day])")
                                .font(.zenCaption)
                                .foregroundColor(.zenSecondary)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.zenProgress)
                                .frame(width: 50, height: max(4, CGFloat(weekData[day]) * 1.8))

                            Text(weekDayLabel(day))
                                .font(.zenCaption)
                                .foregroundColor(.zenSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .padding()
            .background(Color.zenCardBackground)
            .cornerRadius(12)
            .padding(.horizontal)

            // 过去7天总结
            VStack(spacing: 12) {
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
        .padding(.vertical)
    }

    // MARK: - Trend Analysis
    private var trendAnalysisView: some View {
        VStack(spacing: 16) {
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
                                .frame(width: 120, alignment: .leading)
                            ProgressView(value: item.productivity)
                                .tint(.zenProgress)
                                .frame(maxWidth: .infinity)
                            Text("\(Int(item.productivity * 100))%")
                                .font(.zenCaption)
                                .foregroundColor(.zenSecondary)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
            .padding()
            .background(Color.zenCardBackground)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: - Helper Data
    private var weekData: [Int] {
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

// MARK: - Compact Stat Card Component
struct CompactStatCard: View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct CompactStatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        CompactStatisticsView()
    }
}
