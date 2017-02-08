//
//  UIStackLayoutView.swift
//  StackLayoutView
//
//  Created by steven on 4/2/17.
//  Copyright © 2017年 Steven lv. All rights reserved.
//

import UIKit

public enum UIStackLayoutAlign: Int {
    case leading = 0
    case trailing = 1
    case center
    static var top: UIStackLayoutAlign {
        get {
            return .leading
        }
    }
    static var bottom: UIStackLayoutAlign {
        get {
            return .trailing
        }
    }
}

@IBDesignable
public class UIStackLayoutView: UIView {
    
    @IBInspectable public var axis: UILayoutConstraintAxis = .horizontal {
        didSet {
            guard oldValue != axis else {
                return
            }
            arrangedSubviewUpdateConstraints()
        }
    }
    
    @IBInspectable public var align: UIStackLayoutAlign = .leading {
        didSet {
            guard oldValue != align else {
                return
            }
            arrangedSubviewUpdateConstraints()
        }
    }
    
    @IBInspectable public var spacing: CGFloat = 0.0 {
        didSet {
            guard oldValue != spacing else {
                return
            }
            updateConstraintsConstant()
        }
    }
    
    public var padding: UIEdgeInsets = UIEdgeInsets.zero {
        didSet {
            guard !UIEdgeInsetsEqualToEdgeInsets(oldValue, padding) else {
                return
            }
            updateConstraintsConstant()
        }
    }
    
    fileprivate(set) var insetConstraints: [NSLayoutConstraint] = []
    
    fileprivate(set) var spaceConstraints: [NSLayoutConstraint] = []
    
    fileprivate(set) var sizeConstraints: [NSLayoutConstraint] = []
    
    fileprivate(set) var subViewConstraints: [NSLayoutConstraint] = []
    
    fileprivate(set) var centerConstraints: [NSLayoutConstraint] = []
    
    fileprivate(set) var arrangedSubviews: [UIView] = []
    
    
    private var NSIBPrototypingLayoutConstraint: AnyClass? {
        get {
            return NSClassFromString("NSIBPrototypingLayoutConstraint")
        }
    }
    
    #if !TARGET_INTERFACE_BUILDER
    public override func awakeFromNib() {
        super.awakeFromNib()
        var skipConstraints = [NSLayoutConstraint]()
        print("\(NSIBPrototypingLayoutConstraint)")
        superview?.constraints.forEach({
            if ($0.firstItem as! NSObject == self || $0.secondItem as! NSObject == self) && ($0.isKind(of: NSIBPrototypingLayoutConstraint!)) {
                print("NSIBPrototypingLayoutConstraint")
                skipConstraints.append($0)
            }
        })
        superview?.removeConstraints(skipConstraints)
    }
    
    public override func addConstraint(_ constraint: NSLayoutConstraint) {
        if constraint.isKind(of: NSIBPrototypingLayoutConstraint!) {
            return
        }
        super.addConstraint(constraint)
    }
    
    #endif
    
    public override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        #if !TARGET_INTERFACE_BUILDER
            subview.translatesAutoresizingMaskIntoConstraints = false
        #endif
        arrangedSubviews.append(subview)
        arrangedSubviewUpdateConstraints()
        
    }
    
    public override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        if let index = arrangedSubviews.index(of: subview) {
            arrangedSubviews.remove(at: index)
        }
        arrangedSubviewUpdateConstraints()
        
    }
    
    public override func updateConstraints() {
        
        removeConstraints(insetConstraints)
        removeConstraints(spaceConstraints)
        removeConstraints(sizeConstraints)
        removeConstraints(subViewConstraints)
        removeConstraints(centerConstraints)
        buildConstraints()
        updateConstraintsConstant()
        addConstraints(insetConstraints)
        addConstraints(spaceConstraints)
        addConstraints(sizeConstraints)
        addConstraints(subViewConstraints)
        addConstraints(centerConstraints)
        // call super.updateConstraints as final step in your implementation
        super.updateConstraints()
    }
    
}

private extension UIStackLayoutView {
    
    enum Priority {
        static let baseWeak: Float = 100
        static let baseMedium: Float = 500
        static let baseStrong: Float = 900
        static let nestDecrease: Float = 0.01
        static let alignIncrease: Float = 0.001
        static let spaceIncrease = Priority.alignIncrease * 2
    }
    
    func buildConstraints() -> Void {
        
        var insetConstraints = [NSLayoutConstraint]()
        var spaceConstraints = [NSLayoutConstraint]()
        var sizeConstraints = [NSLayoutConstraint]()
        var subViewConstraints = [NSLayoutConstraint]()
        var centerConstraints = [NSLayoutConstraint]()
        
        /// priority
        let decrease = Priority.nestDecrease * self.nestDepth()
        let weak = Priority.baseWeak - decrease
        let medium = Priority.baseMedium - decrease
        let strong = Priority.baseStrong - decrease
        /// relationBy
        let nonAxialAttriStart: NSLayoutAttribute = (axis == .horizontal) ? .top : .leading
        let nonAxialAttriEnd: NSLayoutAttribute = (axis == .horizontal) ? .bottom : .trailing
        let axialAttriStart: NSLayoutAttribute = (axis == .horizontal) ? .leading : .top
        let axialAttriEnd: NSLayoutAttribute = (axis == .horizontal) ? .trailing : .bottom
        /// align
        let alignEnd: Bool = (align == .trailing) || (align == .bottom)
        
        let alignCenter: Bool = (align == .center)
        
        var previous: UIView?
        let count = subviews.count
        subviews.enumerated().forEach {
            
            let huggingVertical = $0.element.contentHuggingPriority(for: .vertical)
            let huggingHorizontal = $0.element.contentHuggingPriority(for: .horizontal)
            let compressionVertical = $0.element.contentCompressionResistancePriority(for: .vertical)
            let compressionHorizontal = $0.element.contentCompressionResistancePriority(for: .horizontal)
            
            let nonAxailHugging = (axis == .horizontal) ? huggingVertical : huggingHorizontal
            let nonAxailCompression = (axis == .horizontal) ? compressionVertical : compressionHorizontal
            for relation in [NSLayoutRelation.lessThanOrEqual, .greaterThanOrEqual] {
                self.buildConstraints(item: $0.element, attribute: nonAxialAttriStart, relatedBy: relation, toItem: self, attribute: nonAxialAttriStart, block: { (start: NSLayoutConstraint) in
                    insetConstraints.append(start)
                    start.priority = nonAxailCompression > Priority.baseStrong ? medium : strong
                    if relation == .lessThanOrEqual {
                        start.priority = nonAxailHugging < Priority.baseWeak ? medium : weak
                    }
                })
            }
            for relation in [NSLayoutRelation.lessThanOrEqual, .greaterThanOrEqual] {
                self.buildConstraints(item: self, attribute: nonAxialAttriEnd, relatedBy: relation, toItem: $0.element, attribute: nonAxialAttriEnd, block: { (end: NSLayoutConstraint) in
                    insetConstraints.append(end)
                    end.priority = nonAxailHugging < Priority.baseStrong ? medium : strong
                    if relation == .lessThanOrEqual {
                        end.priority = nonAxailHugging < Priority.baseWeak ? medium : weak
                    }

                    let delta = alignEnd ? Priority.alignIncrease : -Priority.alignIncrease
                    end.priority += delta
                })
            }
            
            if $0.offset == 0 {
                for relation in [NSLayoutRelation.equal] {
                    self.buildConstraints(item: $0.element, attribute: axialAttriStart, relatedBy: relation, toItem: self, attribute: axialAttriStart, block: { (start:NSLayoutConstraint) in
                        insetConstraints.append(start)
                        start.priority = strong
                        if relation == .lessThanOrEqual {
                            start.priority = weak
                        }
                    })
                }
            }
            
            if $0.offset == count - 1 {
                for relation in [NSLayoutRelation.equal] {
                    self.buildConstraints(item: self, attribute: axialAttriEnd, relatedBy: relation, toItem: $0.element, attribute: axialAttriEnd, block: { (end: NSLayoutConstraint) in
                        insetConstraints.append(end)
                        end.priority = strong
                        if relation == .lessThanOrEqual {
                            end.priority = weak
                        }
                        let delta = alignEnd ? Priority.alignIncrease : -Priority.alignIncrease
                        end.priority += delta
                    })
                }
            }
            
            if let lastView = previous {
                self.buildConstraints(item: $0.element, attribute: axialAttriStart, toItem: lastView, attribute: axialAttriEnd, block: { (space:NSLayoutConstraint) in
                    spaceConstraints.append(space)
                    space.priority = strong + Priority.spaceIncrease
                })
            }
            
            if alignCenter {
                let attributed: NSLayoutAttribute = (axis == .horizontal) ? .centerY : .centerX
                let center = NSLayoutConstraint(item: $0.element, attribute: attributed, relatedBy: .equal, toItem: self, attribute: attributed, multiplier: 1.0, constant: 0)
                centerConstraints.append(center)
                center.priority = medium
            }
            
            if !isValidIntrinsicContentSize(size: $0.element.intrinsicContentSize) {
                
                if !($0.element is UIStackLayoutView) {
                    let widthHug = NSLayoutConstraint(item: $0.element, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .width, multiplier: 1.0, constant: 0)
                    let heightHug = NSLayoutConstraint(item: $0.element, attribute: .height, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .height, multiplier: 1.0, constant: 0)
                    subViewConstraints.append(widthHug)
                    subViewConstraints.append(heightHug)
                    widthHug.priority = huggingHorizontal
                    heightHug.priority = huggingVertical
                }
            }
            
            previous = $0.element
        }
        
        
        [NSLayoutAttribute.height, NSLayoutAttribute.width].forEach { (attribute: NSLayoutAttribute) in
            [NSLayoutRelation.greaterThanOrEqual,.lessThanOrEqual].forEach({ (relation:NSLayoutRelation) in
                self.buildConstraints(item: self, attribute: attribute, relatedBy: relation, toItem: nil, attribute: .notAnAttribute, block: { (size: NSLayoutConstraint) in
                    sizeConstraints.append(size)
                    var axis = UILayoutConstraintAxis.vertical
                    if attribute == NSLayoutAttribute.width {
                        axis = .horizontal
                    }
                    var priority = self.contentCompressionResistancePriority(for: axis)
                    if relation == .lessThanOrEqual {
                        priority = self.contentHuggingPriority(for: axis)
                    }
                    size.priority = priority
                })
            })
        }
        
        self.insetConstraints.removeAll()
        self.spaceConstraints.removeAll()
        self.sizeConstraints.removeAll()
        self.subViewConstraints.removeAll()
        self.centerConstraints.removeAll()
        self.insetConstraints.append(contentsOf: insetConstraints)
        self.spaceConstraints.append(contentsOf: spaceConstraints)
        self.sizeConstraints.append(contentsOf: sizeConstraints)
        self.subViewConstraints.append(contentsOf: subViewConstraints)
        self.centerConstraints.append(contentsOf: centerConstraints)
    }
    
    func updateConstraintsConstant() -> Void {
        insetConstraints.forEach {
            switch $0.firstAttribute {
            case .top:
                $0.constant = padding.top
            case .leading:
                $0.constant = padding.left
            case .trailing:
                $0.constant = padding.right
            case .bottom:
                $0.constant = padding.bottom
            default:
                assert(false, "unexpected attribute \($0.firstAttribute)")
                break
            }
        }
        
        spaceConstraints.forEach{ $0.constant = spacing }
        
        let totalSpacing = subviews.count > 1 ? spacing * CGFloat(subviews.count - 1) : 0
        sizeConstraints.forEach {
            if $0.firstAttribute == .width {
                $0.constant = padding.left + padding.right + (axis == .horizontal ? totalSpacing : 0)
            }else if $0.firstAttribute == .height {
                $0.constant = padding.top + padding.bottom + (axis == .horizontal ? 0 : totalSpacing)
            }else {
                assert(false, "unexpected attribute \($0.firstAttribute)")
            }
        }
        
    }
    
    func arrangedSubviewUpdateConstraints() -> Void {
        #if TARGET_INTERFACE_BUILDER
            self.setNeedsLayout()
        #else
            self.setNeedsUpdateConstraints()
        #endif
    }
    
    func nestDepth() -> Float {
        var depth: Float = 0.0
        if let view = self.superview as? UIStackLayoutView {
            depth += 1.0
            depth += view.nestDepth()
        }
        return depth
    }
    
    func buildConstraints(item view1: UIView,
                     attribute attr1: NSLayoutAttribute,
                  relatedBy relation: NSLayoutRelation = .greaterThanOrEqual,
                        toItem view2: UIView?,
                     attribute attr2: NSLayoutAttribute,
                    multiplier ratio: CGFloat = 1,
                      constant const: CGFloat = 0,
                     priority factor: CGFloat = 1000,
                     block: (_ constraint: NSLayoutConstraint) -> Void) -> Void {
        let greater = NSLayoutConstraint(item: view1, attribute: attr1, relatedBy: relation, toItem: view2, attribute: attr2, multiplier: ratio, constant: const)
        block(greater)
    }
    
    func isValidIntrinsicContentSize(size: CGSize) -> Bool {
        return !(size.width < 0 || size.height < 0)
    }
}

extension UIStackLayoutView {
    @IBInspectable public var rightPadding: CGFloat {
        get {
            return padding.right
        }
        set {
            padding.right = newValue
        }
    }
    
    @IBInspectable public var leftPadding: CGFloat {
        get {
            return padding.left
        }
        set {
            padding.left = newValue
        }
    }
    
    @IBInspectable public var topPadding: CGFloat {
        get {
            return padding.top
        }
        set {
            padding.top = newValue
        }
    }
    
    @IBInspectable public var bottomPadding: CGFloat {
        get {
            return padding.bottom
        }
        set {
            padding.bottom = newValue
        }
    }
}
