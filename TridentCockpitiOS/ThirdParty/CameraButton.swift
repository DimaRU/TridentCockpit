//
//  CameraButton.swift
//  TenStats
//
//  Created by Olivier Destrebecq on 1/16/16.
//  Copyright © 2016 MobDesign. All rights reserved.
//  Tuned by Dmitriy Borovikov, 2010

import UIKit

@IBDesignable
class CameraButton: UIButton {
    
    @IBInspectable var buttonColor: UIColor = UIColor.red
    @IBInspectable var ringColor: UIColor = UIColor.white
    @IBInspectable var disabledColor: UIColor = UIColor.black
    @IBInspectable var disabledRingColor: UIColor = UIColor(white: 0.8, alpha: 1)

    private let outerRingLineWidth: CGFloat = 4
    private let outerInsets: CGFloat = 3
    private let circleInsets: CGFloat = 6
    
    //create a new layer to render the various circles
    var pathLayer: CAShapeLayer!
    let animationDuration = 0.4
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    //common set up code
    func setup() {
        //add a shape layer for the inner shape to be able to animate it
        self.pathLayer = CAShapeLayer()
        
        //show the right shape for the current state of the control
        self.pathLayer.path = self.currentInnerPath().cgPath
        
        //don't use a stroke color, which would give a ring around the inner circle
        self.pathLayer.strokeColor = nil
        
        //set the color for the inner shape
        self.pathLayer.fillColor = isEnabled ? buttonColor.cgColor : disabledColor.cgColor
        
        //add the path layer to the control layer so it gets drawn
        self.layer.addSublayer(self.pathLayer)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //clear the title
        self.setTitle("", for:UIControl.State.normal)
        
        //add out target for event handling
        self.addTarget(self, action: #selector(touchUpInside), for: UIControl.Event.touchUpInside)
        self.addTarget(self, action: #selector(touchDown), for: UIControl.Event.touchDown)
    }
    
    override func prepareForInterfaceBuilder() {
        //clear the title
        self.setTitle("", for:UIControl.State.normal)
    }
    
    override var isSelected: Bool {
        didSet {
            //change the inner shape to match the state
            let morph = CABasicAnimation(keyPath: "path")
            morph.duration = animationDuration;
            morph.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            
            //change the shape according to the current state of the control
            morph.toValue = self.currentInnerPath().cgPath
            
            //ensure the animation is not reverted once completed
            morph.fillMode = CAMediaTimingFillMode.forwards
            morph.isRemovedOnCompletion = false
            
            //add the animation
            self.pathLayer.add(morph, forKey:"")
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            guard oldValue != isEnabled else { return }
            //Create the animation to restore the color of the button
            let colorChange = CABasicAnimation(keyPath: "fillColor")
            colorChange.duration = animationDuration;
            colorChange.toValue = isEnabled ? buttonColor.cgColor : disabledColor.cgColor
            
            //make sure that the color animation is not reverted once the animation is completed
            colorChange.fillMode = CAMediaTimingFillMode.forwards
            colorChange.isRemovedOnCompletion = false
            
            //indicate which animation timing function to use, in this case ease in and ease out
            colorChange.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            
            //add the animation
            pathLayer.add(colorChange, forKey: "darkColor")
        }
    }
    
    @objc func touchUpInside(sender: UIButton) {
        //Create the animation to restore the color of the button
        let colorChange = CABasicAnimation(keyPath: "fillColor")
        colorChange.duration = animationDuration;
        colorChange.toValue = isEnabled ? buttonColor.cgColor : disabledColor.cgColor
        
        //make sure that the color animation is not reverted once the animation is completed
        colorChange.fillMode = CAMediaTimingFillMode.forwards
        colorChange.isRemovedOnCompletion = false
        
        //indicate which animation timing function to use, in this case ease in and ease out
        colorChange.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        
        //add the animation
        pathLayer.add(colorChange, forKey: "darkColor")
         
        //change the state of the control to update the shape
//        self.isSelected.toggle()
    }
    
    @objc func touchDown(sender: UIButton) {
        //when the user touches the button, the inner shape should change transparency
        //create the animation for the fill color
        let morph = CABasicAnimation(keyPath: "fillColor")
        morph.duration = animationDuration;
        
        //set the value we want to animate to
        morph.toValue = buttonColor.withAlphaComponent(0.5).cgColor
        
        //ensure the animation does not get reverted once completed
        morph.fillMode = CAMediaTimingFillMode.forwards
        morph.isRemovedOnCompletion = false
        
        morph.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        pathLayer.add(morph, forKey:"")
    }
    
    override func draw(_ rect: CGRect) {
        //always draw the outer ring, the inner control is drawn during the animations
        let outerRing = UIBezierPath(ovalIn: bounds.insetBy(dx: outerInsets, dy: outerInsets))
        outerRing.lineWidth = outerRingLineWidth
        let color = isEnabled ? ringColor : disabledRingColor
        color.setStroke()
        outerRing.stroke()
    }
    
    func currentInnerPath() -> UIBezierPath {
        //choose the correct inner path based on the control state
        if isSelected {
            return innerSquarePath()
        } else {
            return innerCirclePath()
        }
    }
    
    func innerCirclePath() -> UIBezierPath {
        let inset = circleInsets + outerInsets
        return UIBezierPath(roundedRect: bounds.insetBy(dx: inset, dy: inset), cornerRadius: bounds.width / 2 - inset)
    }
    
    func innerSquarePath() -> UIBezierPath {
        let outerbox = bounds.insetBy(dx: outerInsets, dy: outerInsets)
        let rectbox = outerbox.insetBy(dx: outerbox.width * 0.3, dy: outerbox.height * 0.3)
        return UIBezierPath(roundedRect: rectbox, cornerRadius: 3)
    }
}
