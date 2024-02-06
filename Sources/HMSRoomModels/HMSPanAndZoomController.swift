//
//  HMSMTLVideoView.swift
//  HMSSDK
//
//  Created by Pawan Dixit on 09/08/2022.
//  Copyright © 2022 100ms. All rights reserved.
//

import UIKit

@objcMembers internal class HMSPanAndZoomController: NSObject {
    
    internal var isZoomAndPanEnabled: Bool = false {
        didSet {
            
            if !isZoomAndPanEnabled {
                resetZoomAndPan()
            }
            
            pinchGesture.isEnabled = isZoomAndPanEnabled
            panGesture.isEnabled = isZoomAndPanEnabled
        }
    }
    
    private weak var targetView: UIView?
    
    internal var isZoomed = false
    private var orientation: UIInterfaceOrientation
    
    private var pinchGesture: UIPinchGestureRecognizer!
    private var panGesture: UIPanGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    
    private static func isMetalAvailable() -> Bool {
        return MTLCreateSystemDefaultDevice() != nil
    }
    
    let parentView: UIView
    let tapBlock: (() -> Void)?
    internal init(targetView: UIView, tapBlock: (() -> Void)?) {
        self.tapBlock = tapBlock
        self.targetView = targetView
        
        parentView = UIView(frame: targetView.frame)
        parentView.addConstrained(subview: targetView)
        
        orientation = UIInterfaceOrientation.current
        super.init()
        configure()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    private func configure() {
        guard let targetView = self.targetView else { return }
        
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(sender:)))
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(pan(sender:)))
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tap(sender:)))
        
        panGesture.delegate = self;
        pinchGesture.delegate = self;
        
        targetView.addGestureRecognizer(pinchGesture)
        targetView.addGestureRecognizer(panGesture)
        targetView.addGestureRecognizer(tapGesture)
        
        panGesture.isEnabled = false
        pinchGesture.isEnabled = false
        tapGesture.isEnabled = tapBlock != nil
        
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) {[weak self] _ in
            
            guard let self = self else { return }
            
            guard self.isZoomAndPanEnabled else { return }
            
            // Sometimes the UIInterfaceOrientation is not updated with orientationDidChangeNotification notification, observed specially in the iPad. So pushing the check on next cycle
            DispatchQueue.main.async {
                
                if (UIInterfaceOrientation.current.isLandscape && self.orientation.isPortrait)
                    || (UIInterfaceOrientation.current.isPortrait && self.orientation.isLandscape) {
                    self.orientation = UIInterfaceOrientation.current
                    
                    self.resetZoomAndPan()
                }
            }
        }
    }
    
    internal func resetZoomAndPan() {
        guard let targetView = self.targetView else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            targetView.transform = CGAffineTransform.identity
            targetView.center = CGPoint(x: targetView.bounds.width/2, y: targetView.bounds.height/2)
        }, completion: { _ in
            self.isZoomed = false
        })
    }
}

extension HMSPanAndZoomController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

internal extension HMSPanAndZoomController {
    
    func tap(sender: UITapGestureRecognizer) {
        
        switch sender.state {
        case .ended:
            tapBlock?()
        default:
            break
        }
    }
    
    func pan(sender: UIPanGestureRecognizer) {
        
        switch sender.state {
        case .changed:
            if self.isZoomed {
                let translation = sender.translation(in: targetView)
                
                if let view = sender.view {
                    view.center = CGPoint(x: view.center.x + translation.x * currentScale, y: view.center.y + translation.y * currentScale)
                }
                sender.setTranslation(CGPoint.zero, in: targetView)
            }
        default:
            break
        }
    }
    
    func pinch(sender:UIPinchGestureRecognizer) {
        guard let targetView = self.targetView else { return }
        
        switch sender.state {
        case .began:
            let newScale = currentScale * sender.scale
            if newScale > 1 {
                self.isZoomed = true
            }
        case .changed:
            guard let view = sender.view else { return }
            
            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX, y: sender.location(in: view).y - view.bounds.midY)
            
            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y).scaledBy(x: sender.scale, y: sender.scale).translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
            
            var newScale = currentScale * sender.scale
            
            if newScale < 1 {
                // reset
                newScale = 1
                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
                targetView.transform = transform
                sender.scale = 1
            } else {
                view.transform = transform
                sender.scale = 1
            }
            
        case .ended, .failed, .cancelled:
            
            let newScale = currentScale * sender.scale
            
            if newScale <= 1.0 {
                UIView.animate(withDuration: 0.3, animations: {
                    
                    targetView.transform = CGAffineTransform.identity
                    targetView.center = CGPoint(x: targetView.bounds.width/2, y: targetView.bounds.height/2)
                }, completion: { _ in
                    self.isZoomed = false
                })
            }
        default:
            break
        }
    }
    
    var currentScale: CGFloat {
        guard let targetView = self.targetView else { return 1 }
        return targetView.frame.size.width / targetView.bounds.size.width
    }
}

extension UIInterfaceOrientation {
    
    static var current: UIInterfaceOrientation {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .portrait
        } else {
            // Fallback on earlier versions
            return UIApplication.shared.statusBarOrientation
        }
    }
}
