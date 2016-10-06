/*
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A custom check box used in the lists. It supports designing live in Interface Builder.
*/

import UIKit

//@IBDesignable  class CheckBox: UIControl {
      class CheckBox: UIControl {
    // MARK: Properties
    
    // IB Designables is generating error msg and crashing
     
//    @IBInspectable  var isChecked: Bool {
        var isChecked: Bool {
        get {
            return checkBoxLayer.isChecked
        }
        
        set {
            checkBoxLayer.isChecked = newValue
        }
    }

//    @IBInspectable  var strokeFactor: CGFloat {
          var strokeFactor: CGFloat {
        set {
            checkBoxLayer.strokeFactor = newValue
        }

        get {
            return checkBoxLayer.strokeFactor
        }
    }
    
//    @IBInspectable  var insetFactor: CGFloat {
          var insetFactor: CGFloat {
        set {
            checkBoxLayer.insetFactor = newValue
        }

        get {
            return checkBoxLayer.insetFactor
        }
    }
    
//    @IBInspectable  var markInsetFactor: CGFloat {
          var markInsetFactor: CGFloat {
        set {
            checkBoxLayer.markInsetFactor = newValue
        }
    
        get {
            return checkBoxLayer.markInsetFactor
        }
    }
    
    // MARK: Overrides
    
    override  func didMoveToWindow() {
        if let window = window {
            contentScaleFactor = window.screen.scale
        }
    }

//    override  class func layerClass() -> AnyClass {
//        override  class func layer
//        return CheckBoxLayer.self
//    }
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    override  func tintColorDidChange() {
        super.tintColorDidChange()
        
        checkBoxLayer.tintColor = tintColor.cgColor
    }

    // MARK: Convenience
    
    var checkBoxLayer: CheckBoxLayer {
        return layer as! CheckBoxLayer
    }
}











































