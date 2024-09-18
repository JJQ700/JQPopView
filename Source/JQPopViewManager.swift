//
//  JQPopViewManager.swift
//  GSY
//
//  Created by 纪 on 2024/9/3.
//

import UIKit

class JQPopViewManager {
    
    public static let share = JQPopViewManager()
    
    /// 调试模式
    var logStyle: JQPopViewLogStyle = .no
    
    /// 按弹窗顺序存储已显示的 popview
    var allPopViewArray: [JQPopView] = Array()
    
    /// 储存待移除的popView
    var removeList: NSHashTable = NSHashTable<AnyObject>(options: [.weakMemory])
    
    ///  parentView 类名 :  parentView下的所有popView （优先级 升序）
    var popViewDic: [String: [JQPopView]] = Dictionary()
    
    lazy var infoView: UILabel = {
        let view = UILabel()
        view.backgroundColor = .orange
        view.textAlignment = .center
        view.font = UIFont.systemFont(ofSize: 11)
        view.frame = CGRect(x: UIScreen.main.bounds.width - 70, y: 40, width: 60, height: 10)
        view.layer.cornerRadius = 1
        view.layer.masksToBounds = true
        let superView = UIView.keyWindow()
        superView.addSubview(view)
        return view
    }()
    
    /// 获取当前页面指定编队的所有popView
    func getAllPopViewForPopView(_ popView: JQPopView) -> Array<JQPopView> {
        
        guard let key = popView.parentView?.address() else { return [] }
        
        guard let allArray = popViewDic[key] else { return [] }
        
        var array: [JQPopView] = Array()
        
        for obj in allArray {
            
            if popView.groupId == nil && obj.groupId == nil {
                array.append(obj)
                continue
            }
            
            if obj.groupId == popView.groupId {
                array.append(obj)
                continue
            }
            
        }
        
        return array
    }
        

    /// 保存popview
    func savePopView(_ popView: JQPopView) {
        
        if allPopViewArray.contains(popView) { return }
        
        if let parentView = popView.parentView {
            
            let key = parentView.address()
            
            if var array = popViewDic[key] {
                // 升序
                array.append(popView)
                array.sort { $0.priority < $1.priority }
                popViewDic[key] = array
            }else {
                popViewDic[key] = [popView]
            }
            
            allPopViewArray.append(popView)
            
        }
        
        debugLogging()
                
    }
    
    /// 转移popView到待移除队列
    func transferredToRemoveQueueWithPopView(_ popView: JQPopView) {
        
        removeList.add(popView)
                
        // 此时parentView 为nil
        if let key = popView.superview?.address() {
            popViewDic[key]?.removeAll { $0 == popView }
            allPopViewArray.removeAll { $0 == popView }
        }
        
    }
    
    private func consoleLog() {
                        
        let text = """
                    JQPopView日志 ---> : S:\(allPopViewArray.count)个 R:\(removeList.allObjects.count)个
                    """
        
        print(text)
        
    }
    
    private func infoData() {
        
//        let allPopView = popViewDic.values.flatMap{ $0 }
        
        infoView.text = "S:\(allPopViewArray.count) R:\(removeList.allObjects.count)"
    }
    
    /// 日志输出
    func debugLogging() {
                
#if DEBUG
        if logStyle.contains(.window) {
            infoData()
        }
        
        if logStyle.contains(.console) {
            consoleLog()
        }
#else
        
#endif
        
    }
    
    /// 删除所有popView
    func removeAll() {
                
        for obj in allPopViewArray {
            
            obj.dismissWithStyle(.none, duration: 0, isRemove: true)
        }
        
    }
    
    /// 删除popview
    func removePopView(_ popView: JQPopView) {
        
        popView.dismissWithStyle(.none, duration: 0, isRemove: true)
        
        debugLogging()
        
    }
    
    /// 删除最后一个popview
    func removeLast() {
        
        if let lastObj = allPopViewArray.last {
            removePopView(lastObj)
        }
        
    }
    
    /// 根据标识获取指定popview
    func getPopView(identifier: String) -> JQPopView? {
        
        for obj in allPopViewArray {
            if obj.identifier == identifier {
                return obj
            }
        }
        
        return nil
    }
}

fileprivate extension UIView {
    
    func address() -> String {
        let str = "\(Unmanaged.passUnretained(self).toOpaque())"
        return str
    }
    
    
    
}
