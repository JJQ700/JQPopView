//
//  JQPopView.swift
//  GSY
//
//  Created by 纪 on 2024/8/29.
//

import UIKit

private let JQPopViewDefaultDuration : TimeInterval = -1

typealias JQ_Block_Void = (() -> ())

typealias JQ_Block_Point = ((_ point: CGPoint) -> ())

typealias JQ_Block_KeyBoardChange = ((_ beginFrame: CGRect, _ endFrame: CGRect, _ duration: CGFloat) -> ())

typealias JQ_Block_AlertCountDown = ((_ popView: JQPopView, _ timeInterval: TimeInterval) -> ())

fileprivate func degreesToRadians(_ angle: Double) -> Double {
    return angle / 180.0 * .pi
}

class JQPopView: UIView {
    
    ///  代理 支持多代理
    weak var delegate: JQPopViewProtocol?
        
    /// 自定义添加view
    private(set) var customView: UIView!
    
    /// 父视图
    private(set) weak var parentView: UIView? = UIView.keyWindow()
                
    /// 记录自定义view原始Frame
    private var originFrame: CGRect = .zero
    
    /// 标识 默认为空
    private(set) var identifier: String?
    
    /// 弹窗位置 默认JQHemStyleCenter
    var hemStyle: JQHemStyle = .center
     
    /// 显示时动画弹窗样式 默认JQPopStyleNO
    var popStyle: JQPopStyle = .none
    
    /// 移除时动画弹窗样式 默认JQDismissStyleNO
    var dismissStyle: JQDismissStyle = .none
    
    /// pop 弹簧阻尼
    var popSpringDamping: CGFloat = 0.4
    
    ///  dismiss 弹簧阻尼
    var dismissSpringDamping: CGFloat = 0.4
    
    /// 弹簧阻尼
    var springDamping: CGFloat = 0.4 {
        didSet {
            popSpringDamping = springDamping
            dismissSpringDamping = springDamping
        }
    }
    
    /// 显示时动画时长，> 0。不设置则使用默认的动画时长 设置成JQPopStyleNO, 该属性无效
    var popDuration: TimeInterval = JQPopViewDefaultDuration
    
    /// 隐藏时动画时长，>0。不设置则使用默认的动画时长  设置成JQDismissStyleNO, 该属性无效
    var dismissDuration: TimeInterval = JQPopViewDefaultDuration
    
    /// 弹窗垂直方向(X)偏移量校准 默认0
    var adjustX: CGFloat = 0 {
        didSet {
            setCustomViewFrameWithHeight(0)
        }
    }
    
    /// 弹窗垂直方向(Y)偏移量校准 默认0
    var adjustY: CGFloat = 0 {
        didSet {
            setCustomViewFrameWithHeight(0)
        }
    }
    
    /// 显示时点击背景是否移除弹窗，默认为NO
    var isClickBgDismiss: Bool = false
    
    /// 是否监听屏幕旋转，默认为YES ===  parentView 全屏的时候才会改变
    var isObserverScreenRotation: Bool = true
    
    /// 弹窗和键盘的距离 默认10
    var avoidKeyboardSpace: CGFloat = 10
    
    /// 显示多长时间 默认0 不会消失
    var showTime: Int = 0
    
    /// 自定view圆角方向设置  默认UIRectCornerAllCorners  当cornerRadius>0时生效
    var rectCorners: UIRectCorner?
    
    /// 自定义view圆角大小
    var cornerRadius: CGFloat = 0
    
    /// 弹出震动反馈 默认NO
    var isImpactFeedback: Bool = false
    
    //************ 手势 ****************
    var tapGesture: UITapGestureRecognizer!
    
    var panGesture: UIPanGestureRecognizer!
    
    //************ 群组相关属性 (同一父视图) ****************
    
    /// 群组标识 统一给弹窗编队 方便独立管理 默认为nil,统一全局处理
    var groupId: String?
    
    /// 是否堆叠 默认NO  如果是YES  priority优先级不生效
    var isStack: Bool = false
    
    /// 单显示 默认NO  移出当前页面的所有popview 只添加当前popview
    var isSingle: Bool = false
    
    /// 优先级 范围0~1000 (默认0,遵循先进先出) isStack和isSingle为NO的时候生效
    var priority: Int = 0
    
    //************ 拖拽手势相关属性 ****************
    
    /// 拖拽方向 默认 不可拖拽
    var dragStyle: JQDragStyle = [.none]
    
    /// X轴或者Y轴拖拽移除临界距离 范围(0 ~ +∞)  默认0 不拖拽移除  基使用于dragStyle
    var dragDistance: CGFloat = 0
    
    /// 拖拽移除动画类型 默认同dismissStyle
    var dragDismissStyle: JQDismissStyle = .none
    
    /// 拖拽消失动画时间 默认同 dismissDuration
    var dragDismissDuration: TimeInterval = JQPopViewDefaultDuration
    
    /// 拖拽复原动画时间 默认0.25s
    var dragReboundTime: TimeInterval = 0.25
    
    /// 轻扫方向 默认 不可轻扫  前提开启dragStyle
    var sweepStyle: JQSweepStyle = .none
    
    /// 轻扫速率 控制轻扫移除 默认1000  基于使用sweepStyle
    var swipeVelocity: CGFloat = 1000
    
    /// 轻扫移除的动画 默认JQSweepDismissStyleVelocity
    var sweepDismissStyle: JQSweepDismissStyle = .velocity
    
    /// 当前正在拖拽的是否是 scrollView
    private var isDragScrollView: Bool = false
    
    /// 标记popView中是否有UIScrollView, UITableView, UICollectionView
    private var scrollView: UIScrollView?
    
    //************ block ****************
    
    /// 点击背景
    var bgClickBlock: JQ_Block_Void?
    
    /// 弹窗pan手势偏移
    var panOffsetBlock: JQ_Block_Point?
    
    // ************ 生命周期回调(Block) ************
    
    /// 将要显示 回调
    var popViewWillPopBlock: JQ_Block_Void?
    
    /// 已经显示完毕 回调
    var popViewDidPopBlock: JQ_Block_Void?
    
    /// 将要开始移除 回调
    var popViewWillDismissBlock: JQ_Block_Void?
    
    /// 已经移除完毕 回调
    var popViewDidDismissBlock: JQ_Block_Void?
    
    /// popview 已经释放 回调
    var popViewReleaseBlock: JQ_Block_Void?
    
    /// 倒计时 回调
    var popViewCountDownBlock: JQ_Block_AlertCountDown?
    
    // ************ 背景层 ************
    
    /// 背景层
    private var backgroundView: JQPopViewBgView = JQPopViewBgView()
    
    /// 背景颜色 默认rgb(0,0,0)
    var bgColor: UIColor = .black {
        didSet {
            backgroundView.backgroundColor = getBackgroundColor()
        }
    }
    
    /// 显示时背景的透明度，取值(0.0~1.0)，默认为0.3
    var bgAlpha: CGFloat = 0.3 {
        didSet {
            backgroundView.backgroundColor = getBackgroundColor()
        }
    }
    
    /// 是否隐藏背景 默认NO
    var isHideBg: Bool = false {
        didSet {
            backgroundView.isHideBg = isHideBg
        }
    }
    
    // ************ 键盘 ************
    
    /// 是否规避键盘 默认YES
    var isAvoidKeyboard: Bool = true
    
    /// 键盘第一响应的view
    private weak var textFieldView: UIView?
    
    /// 规避键盘偏移量
    private var avoidKeyboardOffset: CGFloat = 0
    
    /// 是否弹出键盘
    private var isShowKeyboard: Bool = false
    
    /// 倒计时 dismiss
    private var countdownTimer: DispatchSourceTimer?
    
    /// 键盘将要弹出
    var keyboardWillShowBlock: JQ_Block_Void?
    
    /// 键盘弹出完毕
    var keyboardDidShowBlock: JQ_Block_Void?
    
    /// 键盘将要收起
    var keyboardWillHideBlock: JQ_Block_Void?
    
    /// 键盘收起完毕
    var keyboardDidHideBlock: JQ_Block_Void?
    
    
    // MARK: - ****** Life Cycle 控制器生命周期 ******    
    convenience init(customView: UIView,
                     parentView: UIView? = nil,
                     identifier: String? = nil) {
        
        self.init(frame: .zero)
        
        if let parentView = parentView {
            self.parentView = parentView
        }
       
        self.customView = customView
        
        if let identifier = identifier, !identifier.isEmpty {
            self.identifier = identifier
        }
        
        commonInit()
        addNotify()
        addGesture()
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        
        countdownTimer?.cancel()
        customView.removeObserver(self, forKeyPath: "frame")
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        
        popViewReleaseBlock?()
        delegate?.JQ_PopViewReleaseForPopView?(self)
        
        JQPopViewManager.share.debugLogging()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        let hitView = super.hitTest(point, with: event)
        
        if hitView != customView && hitView == self && isHideBg {
            return nil
        }
        
        return hitView
    }
    
    /// 初始化
    private func commonInit() {
        
        frame = parentView?.bounds ?? .zero
        backgroundView.frame = frame
        
        backgroundColor = .clear
        backgroundView.backgroundColor = .clear
        
        addSubview(backgroundView)
        addSubview(customView)
        
    }
    
    /// 获取背景层的颜色 透明度
    private func getBackgroundColor() -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        bgColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let newColor = UIColor.init(red: red, green: green, blue: blue, alpha: bgAlpha)
        return newColor
    }
    
    // MARK: - ****** 添加手势 ******
    private func addGesture() {
        
        //添加点击手势
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(popViewBgViewTap(tap:)))
        tapGesture.delegate = self
        backgroundView.addGestureRecognizer(tapGesture)
        
        //添加拖拽手势
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(dragPan(panGesture:)))
        panGesture.delegate = self
        customView.addGestureRecognizer(panGesture)
        
    }
    
    /// 点击背景层
    @objc private func popViewBgViewTap(tap: UITapGestureRecognizer) {
        
        bgClickBlock?()
        
        if isShowKeyboard {
            endEditing(true)
        }
        
        if isClickBgDismiss {
            dismiss()
        }
        
    }
    
    //拖拽手势
    @objc private func dragPan(panGesture: UIPanGestureRecognizer) {
        
        if isShowKeyboard { return }
        
        if dragStyle == .none { return }
        
        panOffsetBlock?(CGPoint(x: customView.pv_X - originFrame.origin.x,
                                y: customView.pv_Y - originFrame.origin.y))
        
        // 转换指定视图的坐标系统
        let transP = panGesture.translation(in: customView)
        // 在指定视图的坐标系统中以点/秒为单位的平移速度
        let velocity = panGesture.velocity(in: UIView.keyWindow())
        
        if let scrollView = scrollView, isDragScrollView {
            
            // 含有tableView,collectionView,scrollView
            if scrollView.contentOffset.y <= 0 {
                //如果tableView置于顶端
                if transP.y > 0 {
                    //如果向下拖拽
                    scrollView.contentOffset = .zero
                    scrollView.panGestureRecognizer.isEnabled = false
                    isDragScrollView = false
                    // 向下拖
                    customView.frame = CGRect(x: customView.pv_X, 
                                              y: customView.pv_Y + transP.y,
                                              width: customView.pv_Width,
                                              height: customView.pv_Height)
                }else {
                    //如果向上拖拽
                }
            }
            
        }else {
            
            var customViewX = customView.pv_X
            var customViewY = customView.pv_Y
            
            //X正方向移动
            if dragStyle.contains(.xPositive)  && customViewX >= originFrame.origin.x {
                
                if transP.x > 0 {
                    customViewX += transP.x
                }else if transP.x < 0 && customViewX > originFrame.origin.x {
                    let sumX = customViewX + transP.x
                    customViewX = sumX > originFrame.origin.x ? sumX : originFrame.origin.x
                }
                
            }
            
            //X负方向移动
            if dragStyle.contains(.xNegative)  && customViewX <= originFrame.origin.x {
                
                if transP.x < 0 {
                    customViewX += transP.x
                }else if transP.x > 0 && customViewX < originFrame.origin.x {
                    let sumX = customViewX + transP.x
                    customViewX = sumX < originFrame.origin.x ? sumX : originFrame.origin.x
                }
                
            }
            
            //Y正方向移动
            if dragStyle.contains(.yPositive)  && customViewY >= originFrame.origin.y {
                
                if transP.y > 0 {
                    customViewY += transP.y
                }else if transP.y < 0 && customViewY > originFrame.origin.y {
                    let sumY = customViewY + transP.y
                    customViewY = sumY > originFrame.origin.y ? sumY : originFrame.origin.y
                }
                
            }
            
            //Y反方向移动
            if dragStyle.contains(.yNegative) && customViewY <= originFrame.origin.y {
                
                if transP.y < 0 {
                    customViewY += transP.y
                }else if transP.y > 0 && customViewY < originFrame.origin.y {
                    let sumY = customViewY + transP.y
                    customViewY = sumY > originFrame.origin.y ? sumY : originFrame.origin.y
                }
                
            }
            
            customView.frame = CGRect(x: customViewX, y: customViewY, width: customView.pv_Width, height: customView.pv_Height)
            
        }
        
        panGesture.setTranslation(.zero, in: customView)
        
        if panGesture.state == .ended {
            
            if let scrollView = scrollView {
                scrollView.panGestureRecognizer.isEnabled = true
            }
           
            let velocityX = abs(velocity.x)
            let velocityY = abs(velocity.y)
            
            if velocityX >= swipeVelocity || velocityY >= swipeVelocity {
                //轻扫
                if let scrollView = scrollView, scrollView.contentOffset.y > 0 {
                    return
                }
                
                //可轻扫移除的方向
                var isPositive_x: Bool = false
                var isNegative_x: Bool = false
                var isPositive_y: Bool = false
                var isNegative_y: Bool = false
                
                if dragStyle.contains(.xPositive) && velocity.x > 0 && velocityX >= swipeVelocity {
                    isPositive_x = sweepStyle.contains(.xPositive) ? true : false
                }
                
                if dragStyle.contains(.xNegative) && velocity.x < 0 && velocityX >= swipeVelocity {
                    isNegative_x = sweepStyle.contains(.xNegative) ? true : false
                }
                
                if dragStyle.contains(.yNegative) && velocity.y < 0 && velocityY >= swipeVelocity {
                    isNegative_y = sweepStyle.contains(.yNegative) ? true : false
                }
                
                if dragStyle.contains(.yPositive) && velocity.y > 0 && velocityY >= swipeVelocity {
                    isPositive_y = sweepStyle.contains(.yPositive) ? true : false
                }
                
                sweep(isX_P: isPositive_x, isX_N: isNegative_x, isY_N: isNegative_y, isY_P: isPositive_y)
                
            }else {
                
                //普通拖拽
                var isCanDismiss: Bool = false
                
                if abs(customView.pv_X - originFrame.origin.x) >= dragDistance && dragDistance != 0 {
                    isCanDismiss = true
                }
                
                if abs(customView.pv_Y - originFrame.origin.y) >= dragDistance && dragDistance != 0 {
                    isCanDismiss = true
                }
                
                if isCanDismiss {
                    dismissWithStyle(dragDismissStyle, duration: getDragDismissDuration(), isRemove: true)
                }else {
                    dragRebound()
                }
                
            }
            
        }
        
        func getDragDismissDuration() -> TimeInterval {
            
            if dragDismissDuration == JQPopViewDefaultDuration {
                return getDismissDuration(dismissDuration)
            }else {
                return dragDismissDuration
            }
            
        }
        
        //拖拽松开回位
        func dragRebound() {
            
            UIView.animate(withDuration: dragReboundTime, delay: 0.1, options: [.curveEaseOut]) {
                self.customView.frame = self.originFrame
            }
            
        }
        
        // 横扫移除
        func sweep(isX_P: Bool, isX_N: Bool, isY_N: Bool, isY_P: Bool) {
            
            if !isX_P && !isX_N && !isY_N && !isY_P {
                dragRebound()
                return
            }
            
            if !isY_P && !isY_N && sweepDismissStyle == .smooth {
                
                //X轴可轻扫
                if velocity.x > 0 {
                    // 正向
                    dismissWithStyle(.smoothToRight, duration: dismissDuration, isRemove: true)
                }else {
                    dismissWithStyle(.smoothToLeft, duration: dismissDuration, isRemove: true)
                }
                
                return
                
            }
            
            if !isX_P && !isX_N && sweepDismissStyle == .smooth {
                
                //Y轴可轻扫
                if velocity.y > 0 {
                    // 正向
                    dismissWithStyle(.smoothToBottom, duration: dismissDuration, isRemove: true)
                }else {
                    dismissWithStyle(.smoothToTop, duration: dismissDuration, isRemove: true)
                }
                
                return
                
            }
            
            // 移除，以手势速度飞出
            UIView.animate(withDuration: 0.5) {
                self.backgroundView.backgroundColor = self.changeColorAlpha(color: self.bgColor, alpha: 0)
                self.customView.center = CGPoint(x: isX_P || isX_N ? velocity.x : self.customView.pv_CenterX,
                                                 y: isY_P || isY_N ? velocity.y : self.customView.pv_CenterY)
            } completion: { isFinished in
                self.dismissWithStyle(.fade, duration: 0.1, isRemove: true)
            }
            
        }
        
    }
    
    // MARK: - ****** 添加键盘通知 ******
    private func addNotify() {
        
        //键盘将要显示
        NotificationCenter.default.addObserver(self, 
                                               selector: #selector(keyboardWillShow(notify:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        
        //键盘显示完毕
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidShow(notify:)),
                                               name: UIResponder.keyboardDidShowNotification,
                                               object: nil)
        
        //键盘将要收起
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notify:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        
        //键盘收起完毕
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidHide(notify:)),
                                               name: UIResponder.keyboardDidHideNotification,
                                               object: nil)
        
        // 点击 UITextField
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textFieldViewDidBeginEditing(notify:)),
                                               name: UITextField.textDidBeginEditingNotification,
                                               object: nil)
        
        // 点击 UITextView
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textFieldViewDidBeginEditing(notify:)),
                                               name: UITextView.textDidBeginEditingNotification,
                                               object: nil)
        
        //屏幕旋转
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationChange(notify:)),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        
        
        // customView的frame
        customView.addObserver(self,
                               forKeyPath: "frame",
                               options: [.new, .old],
                               context: nil)
        
    }
    
    @objc private func textFieldViewDidBeginEditing(notify: Notification) {
        
        let clickView = notify.object as? UIView
        
        textFieldView = clickView
        
    }
    
    
    @objc private func keyboardWillShow(notify: Notification) {
        
        keyboardWillShowBlock?()
        
        avoidKeyboardOffset = 0
        
        if !isAvoidKeyboard { return }
        
        // 从通知的 userInfo 中获取动画时间和动画曲线
        if let userInfo = notify.userInfo {
            
            guard let textFieldView = textFieldView else { return }
            
            // 获取动画时间
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
            
            // 获取动画曲线
            let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0
            // 将曲线转为动画选项
            let options = UIView.AnimationOptions(rawValue: curve << 16)
            
            // 键盘位置
            let kbFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
            // 转换坐标
            let viewRectInWindow = textFieldView.superview?.convert(textFieldView.frame, to: UIView.keyWindow()) ?? .zero
            
            let viewMaxY = viewRectInWindow.maxY + avoidKeyboardSpace
            
            let keyboardY = kbFrame.minY
            
            //键盘遮挡到弹窗
            if keyboardY < viewMaxY {
                
                avoidKeyboardOffset = viewMaxY - keyboardY
                
                UIView.animate(withDuration: duration,
                               delay: 0,
                               options: options,
                               animations: {
                    
                    self.customView.pv_Y = self.customView.pv_Y - self.avoidKeyboardOffset
                    
                }, completion: nil)
                
            }
            
        }
        
        
    }
    
    @objc private func keyboardDidShow(notify: Notification) {
        
        isShowKeyboard = true
        
        keyboardDidShowBlock?()
        
    }
    
    @objc private func keyboardWillHide(notify: Notification) {
        
        keyboardWillHideBlock?()
        
        isShowKeyboard = false
        
        guard let userInfo = notify.userInfo else { return }
        
        // 获取动画时间
        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        
        // 获取动画曲线
        let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0
        // 将曲线转为动画选项
        let options = UIView.AnimationOptions(rawValue: curve << 16)
        
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: options,
                       animations: {
            
            self.customView.frame = self.originFrame
            
        }, completion: nil)
        
    }
    
    @objc private func keyboardDidHide(notify: Notification) {
        
        keyboardDidHideBlock?()
        
    }
    
    // MARK: - ****** 监听设备方向 ******
    @objc private func orientationChange(notify: Notification) {
        
        guard let parentView = parentView else { return }
        
        if isObserverScreenRotation && parentView.bounds == UIView.keyWindow().bounds {
            
            DispatchQueue.main.async {
                
                parentView.frame = UIView.keyWindow().bounds
                self.frame = parentView.bounds
                self.backgroundView.frame = self.bounds
                self.setCustomViewFrameWithHeight(0)
                
            }
            
        }
        
    }
    
    // MARK: - ****** 观察者 KVO ******
    /// 观察 自定义view的frame
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "frame" {
            
            // 获取新的 frame
            let newFrame = (change?[.newKey] as? NSValue)?.cgRectValue
            let oldFrame = (change?[.oldKey] as? NSValue)?.cgRectValue
            
            if let newSize = newFrame?.size, let oldSize = oldFrame?.size {
                if !CGSizeEqualToSize(newSize, oldSize) {
                    // 在这里处理 frame 改变的逻辑
                    setCustomViewFrameWithHeight(newSize.height - oldSize.height)
                }
            }
            
        }else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
        
    }
    
    // MARK: - ****** pop 弹出 ******
    
    /// 显示
    public func pop() {
        popWithStyle(popStyle: popStyle, duration: popDuration, isOutStack: false)
    }
    
    /// isOutStack 是否出栈
    func popWithStyle(popStyle: JQPopStyle, duration: TimeInterval, isOutStack: Bool) {
        
        let resDuration: TimeInterval = getPopDuration(duration)
        
        setCustomViewFrameWithHeight(0)
        
        originFrame = customView.frame
        
        var startTimer: Bool = false
        
        if self.superview == nil {
            parentView?.addSubview(self)
        }
        
        if isSingle {
            //单显
            let popViewArr = JQPopViewManager.share.getAllPopViewForPopView(self)
            
            for obj in popViewArr {
                // 移除所有popView和移除定时器
                obj.dismissWithStyle(.none, duration: 0, isRemove: true)
            }
            
            startTimer = true
            
        }else {
            // 多显
            if !isOutStack {
                // 处理隐藏倒数第二个popView
                let popViewArr = JQPopViewManager.share.getAllPopViewForPopView(self)
                
                if popViewArr.count >= 1, let obj = popViewArr.last {
                    
                    if isStack {
                        // 堆叠显示
                        startTimer = true
                    }else if priority >= obj.priority {
                        //置顶显示
                        if obj.isShowKeyboard {
                            obj.endEditing(true)
                        }
                        obj.dismissWithStyle(.fade, duration: 0.2, isRemove: false)
                        startTimer = true
                    }else {
                        self.alpha = 0
                        JQPopViewManager.share.savePopView(self)
                        return
                    }
                    
                }else {
                    startTimer = true
                }
            }
        }
        
        // 代理 回调
        delegate?.JQ_PopViewWillPopForPopView?(self)
        popViewWillPopBlock?()
        
        //动画处理
        popAnimationWithPopStyle(popStyle, duration: resDuration)
        // 震动反馈
        beginImpactFeedback()
        
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + resDuration) {
            
            self.delegate?.JQ_PopViewDidPopForPopView?(self)
            self.popViewDidPopBlock?()
            
            if startTimer {
                self.countdownDismiss()
            }
            
        }
        
        // 保存popView
        JQPopViewManager.share.savePopView(self)
        
    }
    
    /// 倒计时  关闭弹窗
    func countdownDismiss() {
        
        if showTime > 0 {
            
            startCountdown(from: showTime) { [weak self] remainingTime in
                guard let ws = self else {return}
                self?.popViewCountDownBlock?(ws, TimeInterval(remainingTime))
                self?.delegate?.JQ_PopViewCountDownForPopView?(ws, forCountDown: TimeInterval(remainingTime))
            } onFinish: { [weak self] in
                guard let ws = self else {return}
                self?.delegate?.JQ_PopViewCountDownFinishForPopView?(ws)
                self?.dismiss()
            }
            
        }
        
    }
    
    /// 倒计时
    func startCountdown(from seconds: Int, onTick: @escaping (Int) -> Void, onFinish: @escaping () -> Void) {
        var remainingTime = seconds
        
        // 创建一个 DispatchSourceTimer
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        
        // 设置时间间隔为 1 秒，并立即开始
        timer.schedule(deadline: .now(), repeating: 1.0)
        
        // 定义在计时器触发时要执行的代码块
        timer.setEventHandler {
            if remainingTime > 0 {
                remainingTime -= 1
                DispatchQueue.main.async {
                    onTick(remainingTime)
                }
            } else {
                timer.cancel() // 停止计时器
                DispatchQueue.main.async {
                    onFinish() // 倒计时结束，执行完成回调
                }
            }
        }
        
        // 启动计时器
        timer.resume()
        
        countdownTimer = timer
    }
    
    /// 震动反馈
    func beginImpactFeedback() {
        
        if isImpactFeedback {
            let feedBackGenertor = UIImpactFeedbackGenerator(style: .medium)
            feedBackGenertor.impactOccurred()
        }
        
    }
    
    /// 弹出动画
    func popAnimationWithPopStyle(_ popStyle: JQPopStyle, duration: TimeInterval) {
        
        if popStyle == .fade {
            // 渐变出现
            backgroundView.backgroundColor = changeColorAlpha(color: bgColor, alpha: 0)
            customView.alpha = 0
            UIView.animate(withDuration: duration) {
                self.backgroundView.backgroundColor = self.changeColorAlpha(color: self.bgColor, alpha: self.bgAlpha)
                self.customView.alpha = 1
            }
        }else if popStyle != .none {
            //有动画
            alpha = 0
            UIView.animate(withDuration: duration*0.2) {
                self.alpha = 1
            }
            
            let startPosition = customView.layer.position
            
            backgroundView.backgroundColor = changeColorAlpha(color: bgColor, alpha: 0)
            UIView.animate(withDuration: duration) {
                self.backgroundView.backgroundColor = self.changeColorAlpha(color: self.bgColor, alpha: self.bgAlpha)
            }
            
            switch popStyle {
                
            case .fade: break
            case .none: break
            case .scale:
                // 缩放动画，先放大，后恢复至原大小
                animationWithLayer(customView.layer, duration: 0.3*duration/0.7, values: [0, 1.2, 0.8, 1], keyTimes: [0, 0.3, 0.7, 1])
            case .smoothFromTop:
                //顶部 平滑淡入动画
                customView.layer.position = CGPoint(x: startPosition.x, y: -customView.pv_Height*0.5)
                animationPosition(startPosition, duration: duration, damping: 1)
                break
            case .smoothFromLeft:
                customView.layer.position = CGPoint(x: -customView.pv_Width*0.5, y: startPosition.y)
                animationPosition(startPosition, duration: duration, damping: 1)
            case .smoothFromBottom:
                customView.layer.position = CGPoint(x: startPosition.x, y: CGRectGetMaxY(self.frame) + customView.pv_Height*0.5)
                animationPosition(startPosition, duration: duration, damping: 1)
            case .smoothFromRight:
                customView.layer.position = CGPoint(x: CGRectGetMaxX(self.frame) + customView.pv_Width*0.5, y: startPosition.y)
                animationPosition(startPosition, duration: duration, damping: 1)
            case .springFromTop:
                customView.layer.position = CGPoint(x: startPosition.x, y: -customView.pv_Height*0.5)
                animationPosition(startPosition, duration: duration, damping: popSpringDamping)
            case .springFromLeft:
                customView.layer.position = CGPoint(x: -customView.pv_Width*0.5, y: startPosition.y)
                animationPosition(startPosition, duration: duration, damping: popSpringDamping)
            case .springFromBottom:
                customView.layer.position = CGPoint(x: startPosition.x, y: CGRectGetMaxY(self.frame) + customView.pv_Height*0.5)
                animationPosition(startPosition, duration: duration, damping: popSpringDamping)
            case .springFromRight:
                // 右侧 平滑淡入动画 带弹簧
                customView.layer.position = CGPoint(x: CGRectGetMaxX(self.frame) + customView.pv_Width*0.5, y: startPosition.y)
                animationPosition(startPosition, duration: duration, damping: popSpringDamping)
            case .cardDropFromLeft:
                // 顶部左侧 掉落动画
                customView.layer.position = CGPoint(x: startPosition.x, y: -customView.pv_Height*0.5)
                customView.transform = CGAffineTransformMakeRotation(degreesToRadians(15))
                animationCardDrop(startPosition, duration: duration, angle: -5.5, completionAngle: 1.0)
                break
            case .cardDropFromRight:
                // 顶部右侧 掉落动画
                customView.layer.position = CGPoint(x: startPosition.x, y: -customView.pv_Height*0.5)
                customView.transform = CGAffineTransformMakeRotation(degreesToRadians(-15))
                animationCardDrop(startPosition, duration: duration, angle: 5.5, completionAngle: -1.0)
                
            }
            
        }
        
    }
    
    /// 掉落动画
    func animationCardDrop(_ position: CGPoint, duration: TimeInterval, angle: CGFloat, completionAngle: CGFloat) {
                
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: 0.75,
                       initialSpringVelocity: 1,
                       options: .curveEaseIn) {
            self.customView.layer.position = position
        }
        
        UIView.animate(withDuration: duration*0.6) {
            
            self.customView.layer.transform = CATransform3DMakeRotation(degreesToRadians(angle), 0, 0, 0)
            
        } completion: { finished in
            
            UIView.animate(withDuration: duration*0.2) {
                self.customView.transform = CGAffineTransformMakeRotation(degreesToRadians(completionAngle))
            }completion: { finished in
                UIView.animate(withDuration: duration*0.2) {
                    self.customView.transform = CGAffineTransformMakeRotation(0)
                }
            }
            
        }
        
    }
    
    /// 滑动效果 弹簧效果
    func animationPosition(_ position: CGPoint, duration: TimeInterval, damping: CGFloat) {
        
        let velocity: CGFloat = damping == 1 ? 1 : 0.3
        
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: damping,
                       initialSpringVelocity: velocity,
                       options: .curveEaseOut) {
            self.customView.layer.position = position
        }
        
    }
    
    /// 缩放动画
    func animationWithLayer(_ layer: CALayer, duration: TimeInterval, values: [Any], keyTimes: [NSNumber]) {
        
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.duration = duration
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        // 设置每个关键帧的时间点
        animation.keyTimes = keyTimes
        
        // 设置关键帧
        animation.values = values
        animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        
        layer.add(animation, forKey: "scaleAnimation")
        
    }
    
    ///  改变UIColor的Alpha
    func changeColorAlpha(color: UIColor, alpha: CGFloat) -> UIColor {
        
        if color == UIColor.clear {
            return color
        }
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var resAlpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &resAlpha)
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// 展示 动画时间
    func getPopDuration(_ duration: TimeInterval) -> TimeInterval {
        
        if popStyle == .none {
            return 0
        }
        
        if duration <= 0 {
            popDuration = JQPopViewDefaultDuration
        }
        
        if popDuration == JQPopViewDefaultDuration {
            
            if popStyle == .scale {
                return 0.3
            }else if popStyle == .fade {
                return 0.2
            }else {
                return 0.6
            }
            
        }
        
        return popDuration
        
    }
    
    // MARK: - ****** dismiss 移除 ******
    func dismiss() {
        dismissWithStyle(dismissStyle, duration: dismissDuration, isRemove: true)
    }
    
    func dismissWithStyle(_ dismissStyle: JQDismissStyle, duration: TimeInterval, isRemove: Bool) {
        
        let resDuration = getDismissDuration(duration)
        
        delegate?.JQ_PopViewWillDismissForPopView?(self)
        popViewWillDismissBlock?()
        
        // 动画
        dismissAnimationWithDismissStyle(dismissStyle, duration: resDuration)
        
        if !isStack && isRemove && JQPopViewManager.share.getAllPopViewForPopView(self).count > 1 {
            //多显
            DispatchQueue.main.asyncAfter(deadline: .now() + resDuration) {
                // popView出栈
                if !self.isStack && JQPopViewManager.share.getAllPopViewForPopView(self).count > 1 {
                    
                    let popViewArr = JQPopViewManager.share.getAllPopViewForPopView(self)
                    
                    if let obj = popViewArr.last {
                        
                        if obj.superview == nil {
                            obj.parentView?.addSubview(obj)
                        }
                        
                        obj.popWithStyle(popStyle: .fade, duration: 0.25, isOutStack: true)
                    }
                    
                }
                
                self.popViewDidDismissBlock?()
                self.delegate?.JQ_PopViewDidDismissForPopView?(self)
                
                self.removeFromSuperview()
                
            }
        }else if isRemove {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + resDuration) {
                
                self.popViewDidDismissBlock?()
                self.delegate?.JQ_PopViewDidDismissForPopView?(self)
                
                self.removeFromSuperview()
            }
        }
        
    }
    
    override func removeFromSuperview() {
        
        JQPopViewManager.share.transferredToRemoveQueueWithPopView(self)
        super.removeFromSuperview()
       
    }
    
    /// dismiss动画
    private func dismissAnimationWithDismissStyle(_ dismissStyle: JQDismissStyle, duration: TimeInterval) {
        
        if dismissStyle == .fade {
            
            UIView.animate(withDuration: duration) {
                self.backgroundView.backgroundColor = self.changeColorAlpha(color: self.bgColor, alpha: 0)
                self.customView.alpha = 0
            }
            
        }else if dismissStyle == .none {
            
            backgroundView.backgroundColor = changeColorAlpha(color: self.bgColor, alpha: 0)
            customView.alpha = 0
            
        }else {
            
            UIView.animate(withDuration: duration) {
                self.backgroundView.backgroundColor = self.changeColorAlpha(color: self.bgColor, alpha: 0)
            }
            
            UIView.animate(withDuration: duration*0.8) {
                self.alpha = 0
            }
            
            let startPosition = customView.layer.position
            
            switch dismissStyle {
            case .fade: break
            case .none: break
            case .scale:
                animationWithLayer(customView.layer, duration: duration*0.2/0.8, values: [1, 0.66, 0.33, 0.01], keyTimes: [0, 0.3, 0.7, 1])
            case .smoothToTop:
                let endPosition = CGPoint(x: startPosition.x, y: -customView.pv_Height*0.5)
                dismissAnimate(duration, endPosition: endPosition)
            case .smoothToLeft:
                let endPosition = CGPoint(x: -customView.pv_Height*0.5, y: startPosition.y)
                dismissAnimate(duration, endPosition: endPosition)
            case .smoothToBottom:
                let endPosition = CGPoint(x: startPosition.x, y: CGRectGetMaxY(self.frame) + customView.pv_Height * 0.5)
                dismissAnimate(duration, endPosition: endPosition)
            case .smoothToRight:
                let endPosition = customView.layer.position
                dismissAnimate(duration, endPosition: endPosition)
            case .cardDropToLeft:
                var rotateEndY: CGFloat = 0
                UIView.animate(withDuration: duration,
                               delay: 0,
                               usingSpringWithDamping: 0.5,
                               initialSpringVelocity: 1,
                               options: [.curveEaseIn]) {
                    self.customView.transform = CGAffineTransformMakeRotation(-(.pi * 0.75))
                    if self.isLandscape() {
                        rotateEndY = abs(self.customView.pv_Y)
                    }
                    self.customView.layer.position = CGPoint(x: startPosition.x,
                                                             y: CGRectGetMaxY(self.frame) + startPosition.y + rotateEndY)
                    
                }
            case .cardDropToRight:
                var rotateEndY: CGFloat = 0
                UIView.animate(withDuration: duration,
                               delay: 0,
                               usingSpringWithDamping: 0.5, 
                               initialSpringVelocity: 1, 
                               options: [.curveEaseIn]) {
                    self.customView.transform = CGAffineTransformMakeRotation(.pi * 0.75)
                    if self.isLandscape() {
                        rotateEndY = abs(self.customView.pv_Y)
                    }
                    self.customView.layer.position = CGPoint(x: startPosition.x * 1.25,
                                                             y: CGRectGetMaxY(self.frame) + startPosition.y + rotateEndY)
                    
                }
            case .cardDropToTop:
                
                let endPosition = CGPoint(x: startPosition.x, y: -startPosition.y)
                
                UIView.animate(withDuration: duration*0.2) {
                    self.customView.layer.position = CGPoint(x: startPosition.x, y: startPosition.y + 50)
                } completion: { finished in
                    UIView.animate(withDuration: duration*0.8) {
                        self.customView.layer.position = endPosition
                    }
                }
            }
            
        }
        
    }
    
    /// 用户界面当前是否为横向显示。
    func isLandscape() -> Bool {
        
        if #available(iOS 13.0, *) {
            
            let array: Set = UIApplication.shared.connectedScenes
            
            for scene in array {
                
                if let windowScene = scene as? UIWindowScene {
                    
                    let isLandscape = windowScene.interfaceOrientation.isLandscape
                    
                    return isLandscape
                    
                }
            }
            
        }else {
            return UIApplication.shared.statusBarOrientation.isLandscape
        }
        
        return false
        
    }
    
    /// 平滑淡入动画
    func dismissAnimate(_ duration: TimeInterval, endPosition: CGPoint) {
        
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 1.0,
                       options: [.curveEaseOut]) {
            self.customView.layer.position = endPosition
        }
        
    }
    
    func getDismissDuration(_ duration: TimeInterval) -> TimeInterval {
        
        if dismissStyle == .none {
            return 0
        }
        
        if dismissDuration <= 0 {
            dismissDuration = JQPopViewDefaultDuration
        }
        
        if dismissDuration == JQPopViewDefaultDuration {
            
            if popStyle == .scale {
                return 0.3
            }else if popStyle == .fade {
                return 0.2
            }else {
                return 0.6
            }
            
        }
        
        return dismissDuration
        
    }
    
    // MARK: - ***** 界面布局 *****
    
    func setCustomViewFrameWithHeight(_ height: CGFloat) {
        
        switch hemStyle {
        case .center:
            //居中
            customView.pv_X = backgroundView.pv_CenterX - customView.pv_Width * 0.5 + adjustX
            customView.pv_Y = backgroundView.pv_CenterY - customView.pv_Height * 0.5 + adjustY
        case .top:
            //贴顶
            customView.pv_X = backgroundView.pv_CenterX - customView.pv_Width * 0.5 + adjustX
            customView.pv_Y = adjustY
        case .left:
            //贴左
            customView.pv_X = adjustX
            customView.pv_Y = backgroundView.pv_CenterY - customView.pv_Height * 0.5 + adjustY
        case .bottom:
            //贴底
            customView.pv_X = backgroundView.pv_CenterX - customView.pv_Width * 0.5 + adjustX
            customView.pv_Y = backgroundView.pv_Height - customView.pv_Height + adjustY
        case .right:
            //贴右
            customView.pv_X = backgroundView.pv_Width - customView.pv_Width + adjustX
            customView.pv_Y = backgroundView.pv_CenterY - customView.pv_Height * 0.5 + adjustY
        case .topLeft:
            //贴顶和左
            customView.pv_X = adjustX
            customView.pv_Y = adjustY
        case .bottomLeft:
            //贴底和左
            customView.pv_X = adjustX
            customView.pv_Y = backgroundView.pv_Height - customView.pv_Height + adjustY
        case .bottomRight:
            //贴底和右
            customView.pv_X = backgroundView.pv_Width - customView.pv_Width + adjustX
            customView.pv_Y = backgroundView.pv_Height - customView.pv_Height + adjustY
        case .topRight:
            //贴顶和右
            customView.pv_X = backgroundView.pv_Width - customView.pv_Width + adjustX
            customView.pv_Y = adjustY
        }
        
        if !isShowKeyboard {
            originFrame = customView.frame
        }
        
        setCustomViewCorners()
        
    }

    /// 设置圆角
    private func setCustomViewCorners() {
        
        if let rectCorners = rectCorners, cornerRadius > 0 {
            
            let path = UIBezierPath(roundedRect: customView.bounds, byRoundingCorners: rectCorners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
            let layer = CAShapeLayer()
            layer.frame = customView.bounds
            layer.path = path.cgPath
            customView.layer.mask = layer
            
        }
        
    }
    
}

// MARK: - ****** 手势代理 ******
extension JQPopView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if gestureRecognizer == panGesture {
            
            var touchView = touch.view
            
            while touchView != nil {
                if touchView!.isKind(of: UIScrollView.self) {
                    isDragScrollView = true
                    scrollView = touchView as? UIScrollView
                    break
                }else if touchView == customView {
                    isDragScrollView = false
                    break
                }
                touchView = touchView?.next as? UIView
            }
            
        }
        
        return true
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer == tapGesture {
            //如果是点击手势
            let point = gestureRecognizer.location(in: customView)
            let isContain = customView.layer.contains(point)
            if isContain {return false}
        }else if gestureRecognizer == panGesture {
            //如果是自己加的拖拽手势
        }
        
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
        
    }
    
    /// 是否与其他手势共存，一般使用默认值(默认返回NO：不与任何手势共存)
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer == panGesture {
            
            if let scrollPan = NSClassFromString("UIScrollViewPanGestureRecognizer"), let pan = NSClassFromString("UIPanGestureRecognizer") {
                
                if otherGestureRecognizer.isKind(of: scrollPan) || otherGestureRecognizer.isKind(of: pan) {
                    
                    if let view = otherGestureRecognizer.view, view.isKind(of: UIScrollView.self) {
                        return true
                    }
                    
                }
                
            }
            
        }
        
        return false
    }
    
    
    
}

// MARK: - ****** 自定义背景层 ******
class JQPopViewBgView: UIView {
    
    /** 是否隐藏背景 默认NO */
    var isHideBg: Bool = false {
        didSet {
            isHidden = isHideBg
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        let hitView = super.hitTest(point, with: event)
        
        if hitView == self && self.isHideBg {
            return nil
        }
        
        return hitView
    }
    
}
