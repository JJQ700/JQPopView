//
//  JQPopViewProtocol.swift
//  GSY
//
//  Created by 纪 on 2024/8/29.
//

import Foundation

/** 调试日志类型 */
struct JQPopViewLogStyle: OptionSet {
    
    let rawValue: Int
    
    /// 关闭调试信息(窗口和控制台日志输出)
    static let no = JQPopViewLogStyle([])
    
    /// 开启左上角小窗
    static let window = JQPopViewLogStyle(rawValue: 1 << 0)
    
    /// 开启控制台日志输出
    static let console = JQPopViewLogStyle(rawValue: 2 << 1)
    
    /// 开启小窗和控制台日志
    static let all = JQPopViewLogStyle([.window, .console])
}

/** 显示动画样式 */
enum JQPopStyle {
    case fade                       // 默认 渐变出现
    case none                       // 无动画
    case scale                      // 缩放 先放大 后恢复至原大小
    case smoothFromTop              // 顶部 平滑淡入动画
    case smoothFromLeft             // 左侧 平滑淡入动画
    case smoothFromBottom           // 底部 平滑淡入动画
    case smoothFromRight            // 右侧 平滑淡入动画
    case springFromTop              // 顶部 平滑淡入动画 带弹簧
    case springFromLeft             // 左侧 平滑淡入动画 带弹簧
    case springFromBottom           // 底部 平滑淡入动画 带弹簧
    case springFromRight            // 右侧 平滑淡入动画 带弹簧
    case cardDropFromLeft           // 顶部左侧 掉落动画
    case cardDropFromRight          // 顶部右侧 掉落动画
}

/// 消失动画样式
enum JQDismissStyle: Int {
    case fade = 0               // 默认 渐变消失
    case none                   // 无动画
    case scale                  // 缩放
    case smoothToTop            // 顶部 平滑淡出动画
    case smoothToLeft           // 左侧 平滑淡出动画
    case smoothToBottom         // 底部 平滑淡出动画
    case smoothToRight          // 右侧 平滑淡出动画
    case cardDropToLeft         // 卡片从中间往左侧掉落
    case cardDropToRight        // 卡片从中间往右侧掉落
    case cardDropToTop          // 卡片从中间往顶部移动消失
}

/// 主动动画样式(开发中)
enum JQActivityStyle: Int {
    case none = 0               // 无动画
    case scale                  // 缩放
    case shake                  // 抖动
}

/// 弹窗位置
enum JQHemStyle: Int {
    case center = 0             // 居中
    case top                    // 贴顶
    case left                   // 贴左
    case bottom                 // 贴底
    case right                  // 贴右
    case topLeft                // 贴顶和左
    case bottomLeft             // 贴底和左
    case bottomRight            // 贴底和右
    case topRight               // 贴顶和右
}

/// 拖拽方向
struct JQDragStyle: OptionSet {
    let rawValue: Int
    
    static let none            = JQDragStyle([])
    static let xPositive       = JQDragStyle(rawValue: 1 << 0) // X轴正方向拖拽
    static let xNegative       = JQDragStyle(rawValue: 1 << 1) // X轴负方向拖拽
    static let yPositive       = JQDragStyle(rawValue: 1 << 2) // Y轴正方向拖拽
    static let yNegative       = JQDragStyle(rawValue: 1 << 3) // Y轴负方向拖拽
    static let x               = JQDragStyle([.xPositive, .xNegative]) // X轴方向拖拽
    static let y               = JQDragStyle([.yPositive, .yNegative]) // Y轴方向拖拽
    static let all             = JQDragStyle([.x, .y]) // 全向拖拽
}

/// 可轻扫消失的方向
struct JQSweepStyle: OptionSet {
    let rawValue: Int
    
    static let none            = JQSweepStyle([])
    static let xPositive       = JQSweepStyle(rawValue: 1 << 0) // X轴正方向拖拽
    static let xNegative       = JQSweepStyle(rawValue: 1 << 1) // X轴负方向拖拽
    static let yPositive       = JQSweepStyle(rawValue: 1 << 2) // Y轴正方向拖拽
    static let yNegative       = JQSweepStyle(rawValue: 1 << 3) // Y轴负方向拖拽
    static let x               = JQSweepStyle([.xPositive, .xNegative]) // X轴方向拖拽
    static let y               = JQSweepStyle([.yPositive, .yNegative]) // Y轴方向拖拽
    static let all             = JQSweepStyle([.x, .y]) // 全向轻扫
}

/**
   可轻扫消失动画类型 对单向横扫 设置有效
   JQSweepDismissStyleSmooth: 自动适应选择以下其一
   JQDismissStyleSmoothToTop,
   JQDismissStyleSmoothToLeft,
   JQDismissStyleSmoothToBottom ,
   JQDismissStyleSmoothToRight
 */
enum JQSweepDismissStyle: Int {
    case velocity = 0           // 默认加速度 移除
    case smooth = 1             // 平顺移除
}

@objc
protocol JQPopViewProtocol {
    
    /** 点击弹窗 回调 */
    @objc optional func JQ_PopViewBgClickForPopView(_ popView: JQPopView)
    
    /** 长按弹窗 回调 */
    @objc optional func JQ_PopViewBgLongPressForPopView(_ popView: JQPopView)
    
    // ****** 生命周期 ******
    /// 将要显示
    @objc optional func JQ_PopViewWillPopForPopView(_ popView: JQPopView)
    
    /// 已经显示完毕
    @objc optional func JQ_PopViewDidPopForPopView(_ popView: JQPopView)
    
    /// 倒计时进行中 timeInterval:时长
    @objc optional func JQ_PopViewCountDownForPopView(_ popView: JQPopView, forCountDown timeInterval: TimeInterval)
    
    /// 倒计时倒计时完成
    @objc optional func JQ_PopViewCountDownFinishForPopView(_ popView: JQPopView)
    
    /// 将要开始移除
    @objc optional func JQ_PopViewWillDismissForPopView(_ popView: JQPopView)
    
    /// 已经移除完毕
    @objc optional func JQ_PopViewDidDismissForPopView(_ popView: JQPopView)
    
    /// popview 释放内存
    @objc optional func JQ_PopViewReleaseForPopView(_ popView: JQPopView)
    
}
