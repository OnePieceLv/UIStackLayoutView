//
//  ViewController.swift
//  StackLayoutView
//
//  Created by steven on 4/2/17.
//  Copyright © 2017年 Steven lv. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var hiddenViews: [UIView] = []
    
    @IBOutlet weak var linearView: UIStackLayoutView!
    
    @IBOutlet weak var spaceInset: UIStepper!
    
    @IBOutlet weak var container: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    
    @IBAction func changeAxis(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            linearView.axis = .horizontal
        }else {
            linearView.axis = .vertical
        }
    }
    
    
    @IBAction func changeAlign(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            linearView.align = .leading
        case 1:
            linearView.align = .trailing
        case 2:
            linearView.align = .center
        default:
            break
        }
    }
    
    
    @IBAction func changeInset(_ sender: UIStepper) {
        let padding = CGFloat(sender.value)
        linearView.padding = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        
    }

    @IBAction func changeSpacing(_ sender: UIStepper) {
        linearView.spacing = CGFloat(sender.value)

    }
    
    
    @IBAction func addsubviewClick(_ sender: UIButton) {

        let maxNumber = CGFloat(max(30, Int(arc4random() % 100)))
        let text = "hidden"
        let point = sender.convert(CGPoint.init(x: sender.frame.width/2 , y: sender.frame.height/2 ), to: linearView)
        let label = UILabel(frame: CGRect(origin: point, size: CGSize.zero))
        label.font = UIFont.systemFont(ofSize: maxNumber)
        let count = linearView.subviews.count
        let start = text.index(text.startIndex, offsetBy: count % text.characters.count)
        let end = text.index(start, offsetBy: 1)
        let range = Range(uncheckedBounds: (lower: start, upper: end))
        label.text = text.substring(with: range)
        label.text = text
        label.backgroundColor = UIColor(hue: CGFloat(linearView.subviews.count % 10 / 10), saturation: 1, brightness: 1, alpha: 1)
        let tap = UITapGestureRecognizer(target: self, action: #selector(subviewDidTap(sender:)))
        label.addGestureRecognizer(tap)
        label.isUserInteractionEnabled = true
        linearView.addSubview(label)
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func subviewDidTap(sender: UITapGestureRecognizer) -> Void {
        if let view = sender.view {
            view.isHidden = !view.isHidden
            if view.isHidden {
                hiddenViews.append(view)
            }
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }

        }
        
    }
    
    @IBAction func clearSubviewClick(_ sender: UIButton) {
        self.linearView.subviews.forEach({ $0.removeFromSuperview() })
        UIView.animate(withDuration: 0.3) { 
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func showSubview(_ sender: UIButton) {
        hiddenViews.forEach { $0.isHidden = false }
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }

    }
    
    
}

