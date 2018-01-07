//
//  ATImageCropperController.swift
//  ImageCropperDemo
//
//  Created by yakang wang on 2018/1/7.
//  Copyright © 2018年 yakang wang. All rights reserved.
//

import UIKit

fileprivate let BOUNDCE_DURATION: TimeInterval = 0.3
fileprivate let SCALE_FRAME_Y: CGFloat = 100.0

protocol ATImageCropperDelegate: class {
    func imageCropper(_ cropperViewController: ATImageCropperController, didFinished editedImage: UIImage)
    
    func imageCropperDidCancel(_ cropperViewController: ATImageCropperController)
}

class ATImageCropperController: UIViewController {
    
    weak var delegate: ATImageCropperDelegate?
    
    var cropFrame: CGRect = CGRect.zero
    var limitRatio: CGFloat = 0.0
    
    fileprivate var originalImage: UIImage
    fileprivate var editedImage: UIImage?
    fileprivate var showImgView: UIImageView
    
    fileprivate var overlayView: UIView
    fileprivate var ratioView: UIView
    
    fileprivate var oldFrame = CGRect.zero
    fileprivate var largeFrame = CGRect.zero
    
    fileprivate var latestFrame = CGRect.zero
    
    
    deinit {
    }

    init(image originalImage: UIImage, cropFrame: CGRect, limitScaleRatio limitRatio: CGFloat) {
        self.showImgView = UIImageView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        self.originalImage = UIImage()
        self.overlayView = UIView(frame: UIScreen.main.bounds)
        self.ratioView = UIView(frame: cropFrame)
        super.init(nibName: nil, bundle: nil)
        
        self.cropFrame = cropFrame
        self.limitRatio = limitRatio
        self.originalImage = originalImage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initControlBtn()
    }

    override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        return false
    }
    
    func initControlBtn() {
        let confirmBtn = UIButton(frame: CGRect(x: view.frame.size.width - 100.0, y: view.frame.size.height - 50.0, width: 100, height: 50))
        confirmBtn.backgroundColor = UIColor.black
        confirmBtn.titleLabel?.textColor = UIColor.white
        confirmBtn.setTitle("OK", for: .normal)
        confirmBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18.0)
        confirmBtn.titleLabel?.textAlignment = .center
        confirmBtn.titleLabel?.textColor = UIColor.white
        confirmBtn.titleLabel?.lineBreakMode = .byWordWrapping
        confirmBtn.titleLabel?.numberOfLines = 0
        confirmBtn.titleEdgeInsets = UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0)
        confirmBtn.addTarget(self, action: #selector(self.confirm), for: .touchUpInside)
        view.addSubview(confirmBtn)
        
        let cancelBtn = UIButton(frame: CGRect(x: 0, y: view.frame.size.height - 50.0, width: 100, height: 50))
        cancelBtn.backgroundColor = UIColor.black
        cancelBtn.titleLabel?.textColor = UIColor.white
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18.0)
        cancelBtn.titleLabel?.textAlignment = .center
        cancelBtn.titleLabel?.lineBreakMode = .byWordWrapping
        cancelBtn.titleLabel?.numberOfLines = 0
        cancelBtn.titleEdgeInsets = UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0)
        cancelBtn.addTarget(self, action: #selector(self.cancel), for: .touchUpInside)
        view.addSubview(cancelBtn)
    }
    
    func initView() {
        showImgView.isMultipleTouchEnabled = true
        showImgView.isUserInteractionEnabled = true
        showImgView.image = originalImage
        
        // scale to fit the screen
        let oriWidth: CGFloat = cropFrame.size.width
        let oriHeight: CGFloat = originalImage.size.height * (oriWidth / originalImage.size.width)
        let oriX: CGFloat = cropFrame.origin.x + (cropFrame.size.width - oriWidth) / 2
        let oriY: CGFloat = cropFrame.origin.y + (cropFrame.size.height - oriHeight) / 2
        oldFrame = CGRect(x: oriX, y: oriY, width: oriWidth, height: oriHeight)
        latestFrame = oldFrame
        showImgView.frame = oldFrame
        largeFrame = CGRect(x: 0, y: 0, width: limitRatio * oldFrame.size.width, height: limitRatio * oldFrame.size.height)
        addGestureRecognizers()
        view.addSubview(showImgView)
        
        overlayView.alpha = 0.5
        overlayView.backgroundColor = UIColor.black
        overlayView.isUserInteractionEnabled = false
        overlayView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.addSubview(overlayView)
        
        ratioView.layer.borderColor = UIColor.yellow.cgColor
        ratioView.layer.borderWidth = 1.0
        view.addSubview(ratioView)
        
        overlayClipping()
    }
    
    @objc func cancel(_ sender: Any) {
        delegate?.imageCropperDidCancel(self)
    }
    
    @objc func confirm(_ sender: Any) {
        if let image = getSubImage() {
            delegate?.imageCropper(self, didFinished: image)
        }
    }
    
    func overlayClipping(){
        let maskLayer = CAShapeLayer()
        let path: CGMutablePath = CGMutablePath()
        // Left side of the ratio view
        path.addRect(CGRect(x: 0, y: 0, width: ratioView.frame.origin.x, height: overlayView.frame.size.height), transform: .identity)
        // Right side of the ratio view
        path.addRect(CGRect(x: ratioView.frame.origin.x + ratioView.frame.size.width, y: 0, width: overlayView.frame.size.width - ratioView.frame.origin.x - ratioView.frame.size.width, height: overlayView.frame.size.height), transform: .identity)
        // Top side of the ratio view
        path.addRect(CGRect(x: 0, y: 0, width: overlayView.frame.size.width, height: ratioView.frame.origin.y), transform: .identity)
        // Bottom side of the ratio view
        path.addRect(CGRect(x: 0, y: ratioView.frame.origin.y + ratioView.frame.size.height, width: overlayView.frame.size.width, height: overlayView.frame.size.height - ratioView.frame.origin.y + ratioView.frame.size.height), transform: .identity)
        
        maskLayer.path = path
        overlayView.layer.mask = maskLayer
    }
    
    func addGestureRecognizers() {
        // add pinch gesture
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchView))
        view.addGestureRecognizer(pinchGestureRecognizer)
        // add pan gesture
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.panView))
        view.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc func pinchView(_ pinchGestureRecognizer: UIPinchGestureRecognizer) {
        if pinchGestureRecognizer.state == .began || pinchGestureRecognizer.state == .changed {
            showImgView.transform = (showImgView.transform.scaledBy(x: pinchGestureRecognizer.scale, y: pinchGestureRecognizer.scale))
            pinchGestureRecognizer.scale = 1
        }
        else if pinchGestureRecognizer.state == .ended {
            var newFrame: CGRect = showImgView.frame
            newFrame = handleScaleOverflow(newFrame)
            newFrame = handleBorderOverflow(newFrame)
            UIView.animate(withDuration: BOUNDCE_DURATION, animations: {() -> Void in
                self.showImgView.frame = newFrame
                self.latestFrame = newFrame
            })
        }
    }
    
    @objc func panView(_ panGestureRecognizer: UIPanGestureRecognizer) {
        
        if panGestureRecognizer.state == .began || panGestureRecognizer.state == .changed {
            // calculate accelerator
            let absCenterX: CGFloat = cropFrame.origin.x + cropFrame.size.width / 2
            let absCenterY: CGFloat = cropFrame.origin.y + cropFrame.size.height / 2
            let scaleRatio: CGFloat = showImgView.frame.size.width / cropFrame.size.width
            let acceleratorX: CGFloat = 1 - abs(absCenterX - showImgView.center.x) / (scaleRatio * absCenterX)
            let acceleratorY: CGFloat = 1 - abs(absCenterY - showImgView.center.y) / (scaleRatio * absCenterY)
            let translation: CGPoint = panGestureRecognizer.translation(in: showImgView.superview)
            showImgView.center = CGPoint(x: showImgView.center.x + translation.x * acceleratorX, y: showImgView.center.y + translation.y * acceleratorY)
            panGestureRecognizer.setTranslation(CGPoint.zero, in: showImgView.superview)
        }
        else if panGestureRecognizer.state == .ended {
            // bounce to original frame
            var newFrame: CGRect = showImgView.frame
            newFrame = handleBorderOverflow(newFrame)
            UIView.animate(withDuration: BOUNDCE_DURATION, animations: {() -> Void in
                self.showImgView.frame = newFrame
                self.latestFrame = newFrame
            })
        }
    }
    
    func handleScaleOverflow(_ newFrame: CGRect) -> CGRect {
        var newFrame = newFrame
        // bounce to original frame
        let oriCenter = CGPoint(x: newFrame.origin.x + newFrame.size.width / 2, y: newFrame.origin.y + newFrame.size.height / 2)
        if newFrame.size.width < oldFrame.size.width {
            newFrame = oldFrame
        }
        if newFrame.size.width > largeFrame.size.width {
            newFrame = largeFrame
        }
        newFrame.origin.x = oriCenter.x - newFrame.size.width / 2
        newFrame.origin.y = oriCenter.y - newFrame.size.height / 2
        return newFrame
    }
    
    func handleBorderOverflow(_ newFrame: CGRect) -> CGRect {
        var newFrame = newFrame
        // horizontally
        if newFrame.origin.x > cropFrame.origin.x {
            newFrame.origin.x = cropFrame.origin.x
        }
        if newFrame.maxX < cropFrame.size.width {
            newFrame.origin.x = cropFrame.size.width - newFrame.size.width
        }
        // vertically
        if newFrame.origin.y > cropFrame.origin.y {
            newFrame.origin.y = cropFrame.origin.y
        }
        if newFrame.maxY < cropFrame.origin.y + cropFrame.size.height {
            newFrame.origin.y = cropFrame.origin.y + cropFrame.size.height - newFrame.size.height
        }
        // adapt horizontally rectangle
        if showImgView.frame.size.width > showImgView.frame.size.height && newFrame.size.height <= cropFrame.size.height {
            newFrame.origin.y = cropFrame.origin.y + (cropFrame.size.height - newFrame.size.height) / 2
        }
        return newFrame
    }

    func getSubImage() -> UIImage? {
        let squareFrame: CGRect = cropFrame
        let scaleRatio: CGFloat = latestFrame.size.width / originalImage.size.width
        var x: CGFloat = (squareFrame.origin.x - latestFrame.origin.x) / scaleRatio
        var y: CGFloat = (squareFrame.origin.y - latestFrame.origin.y) / scaleRatio
        var w: CGFloat = squareFrame.size.width / scaleRatio
        var h: CGFloat = squareFrame.size.width / scaleRatio
        if latestFrame.size.width < cropFrame.size.width {
            let newW: CGFloat = originalImage.size.width
            let newH: CGFloat = newW * (cropFrame.size.height / cropFrame.size.width)
            x = 0
            y = y + (h - newH) / 2
            w = newH
            h = newH
        }
        let myImageRect = CGRect(x: x, y: y, width: w, height: h)
        let imageRef = originalImage.cgImage
        let subImageRef = imageRef?.cropping(to: myImageRect)
        var size = CGSize.zero
        size.width = myImageRect.size.width
        size.height = myImageRect.size.height
        UIGraphicsBeginImageContext(size)
        let context: CGContext? = UIGraphicsGetCurrentContext()
        if let subImageRef = subImageRef {
            context?.draw(subImageRef, in: myImageRect)
            
            let smallImage = UIImage(cgImage: subImageRef) //UIImage(cgImage: subImageRef ?? CGImage())
            UIGraphicsEndImageContext()
            return smallImage
        }
        return nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
