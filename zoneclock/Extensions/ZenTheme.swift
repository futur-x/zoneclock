//
//  ZenTheme.swift
//  zoneclock
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Zen-inspired minimalist color scheme
//

import SwiftUI

/// 禅意配色方案 - 黑白灰美学
extension Color {
    // MARK: - Zen Colors (Black, White, Gray)

    /// 主要背景色 - 纯白或接近白
    static let zenBackground = Color(white: 0.98)

    /// 次要背景色 - 浅灰
    static let zenSecondaryBackground = Color(white: 0.95)

    /// 卡片背景 - 极浅灰
    static let zenCardBackground = Color(white: 0.97)

    /// 主文字颜色 - 深灰黑
    static let zenPrimary = Color(white: 0.15)

    /// 次要文字颜色 - 中灰（iOS端更深）
    static var zenSecondary: Color {
        #if os(iOS)
        return Color(white: 0.35)  // iOS用更深的灰色
        #else
        return Color(white: 0.5)   // macOS保持中灰
        #endif
    }

    /// 辅助文字颜色 - 浅灰
    static let zenTertiary = Color(white: 0.65)

    /// 分割线颜色 - 极浅灰
    static let zenDivider = Color(white: 0.9)

    /// 强调色 - 深灰（用于按钮等）
    static let zenAccent = Color(white: 0.25)

    /// 激活状态 - 黑色
    static let zenActive = Color(white: 0.1)

    /// 禁用状态 - 浅灰
    static let zenDisabled = Color(white: 0.75)

    /// 进度条颜色 - 深灰
    static let zenProgress = Color(white: 0.3)

    /// 进度条背景 - 极浅灰
    static let zenProgressBackground = Color(white: 0.92)
}

/// 禅意字体方案
extension Font {
    // MARK: - Zen Typography (Thin & Light)

    /// 大标题 - 超细
    static let zenTitle = Font.system(size: 28, weight: .ultraLight)

    /// 标题 - 细
    static let zenHeadline = Font.system(size: 20, weight: .thin)

    /// 副标题 - 细
    static let zenSubheadline = Font.system(size: 16, weight: .light)

    /// 正文 - 细
    static let zenBody = Font.system(size: 14, weight: .light)

    /// 说明文字 - 超细
    static let zenCaption = Font.system(size: 12, weight: .ultraLight)

    /// 数字大标题 - 超细（用于计时器等）
    static let zenNumber = Font.system(size: 48, weight: .ultraLight, design: .rounded)

    /// 数字小标题 - 细
    static let zenNumberSmall = Font.system(size: 24, weight: .thin, design: .rounded)
}

/// 禅意视图修饰器
extension View {
    /// 应用禅意卡片样式
    func zenCard() -> some View {
        self
            .padding()
            .background(Color.zenCardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.zenDivider, lineWidth: 0.5)
            )
    }

    /// 应用禅意按钮样式
    func zenButton() -> some View {
        self
            .font(.zenBody)
            .foregroundColor(.zenBackground)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.zenAccent)
            .cornerRadius(6)
    }
}
