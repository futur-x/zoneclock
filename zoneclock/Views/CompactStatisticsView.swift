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
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("统计")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button("完成") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            #if os(macOS)
            .background(Color(NSColor.windowBackgroundColor))
            #else
            .background(Color(UIColor.systemBackground))
            #endif

            Divider()

            // 标签选择器
            Picker("统计类型", selection: $selectedTab) {
                Text("今日").tag(0)
                Text("本周").tag(1)
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
                        color: .blue
                    )

                    CompactStatCard(
                        title: "完成周期",
                        value: "\(todayStats.completedCycles)",
                        unit: "个",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                }

                HStack(spacing: 12) {
                    CompactStatCard(
                        title: "微休息",
                        value: "\(todayStats.microBreaksCount)",
                        unit: "次",
                        icon: "pause.circle.fill",
                        color: .orange
                    )

                    CompactStatCard(
                        title: "完成率",
                        value: "\(Int(todayStats.completionRate * 100))",
                        unit: "%",
                        icon: "percent",
                        color: .purple
                    )
                }
            }
            .padding(.horizontal)

            // 今日时间分布
            VStack(alignment: .leading, spacing: 12) {
                Text("时间分布")
                    .font(.headline)

                ProgressBar(
                    title: "专注",
                    value: Float(todayStats.totalFocusTime),
                    maxValue: 480,
                    color: .blue
                )

                ProgressBar(
                    title: "休息",
                    value: Float(todayStats.totalBreakTime),
                    maxValue: 120,
                    color: .green
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: - Week Statistics
    private var weekStatisticsView: some View {
        VStack(spacing: 16) {
            // 本周专注时长图表
            VStack(alignment: .leading, spacing: 12) {
                Text("本周专注时长")
                    .font(.headline)

                // 简单的柱状图
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(0..<min(7, weekData.count), id: \.self) { day in
                        VStack(spacing: 4) {
                            Text("\(weekData[day])")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: 50, height: max(4, CGFloat(weekData[day]) * 1.8))

                            Text(weekDayLabel(day))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)

            // 本周总结
            VStack(spacing: 12) {
                HStack {
                    Text("本周总计")
                        .font(.headline)
                    Spacer()
                    Text("\(weekData.reduce(0, +)) 分钟")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                HStack {
                    Text("日均专注")
                    Spacer()
                    let avg = weekData.isEmpty ? 0 : weekData.reduce(0, +) / weekData.count
                    Text("\(avg) 分钟")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("最高记录")
                    Spacer()
                    Text("\(weekData.max() ?? 0) 分钟")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
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
                    .font(.headline)

                HStack {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.green)
                    Text("专注时长提升 15%")
                        .foregroundColor(.green)
                }

                HStack {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.green)
                    Text("完成率提升 8%")
                        .foregroundColor(.green)
                }

                Text("您的专注力正在稳步提升！")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)

            // 最佳专注时段
            VStack(alignment: .leading, spacing: 12) {
                Text("最佳专注时段")
                    .font(.headline)

                ForEach(peakHours, id: \.0) { hour, productivity in
                    HStack {
                        Text("\(hour):00 - \(hour + 1):00")
                            .font(.subheadline)
                            .frame(width: 120, alignment: .leading)
                        ProgressView(value: productivity)
                            .frame(maxWidth: .infinity)
                        Text("\(Int(productivity * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: - Helper Data
    private var weekData: [Int] {
        return weekStats.map { $0.totalFocusTime }
    }

    private var peakHours: [(Int, Double)] {
        [(9, 0.9), (10, 0.85), (14, 0.75), (15, 0.8)]
    }

    private func weekDayLabel(_ index: Int) -> String {
        let days = ["一", "二", "三", "四", "五", "六", "日"]
        return days[index]
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
                    .font(.caption)
                    .foregroundColor(color)
                Spacer()
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
