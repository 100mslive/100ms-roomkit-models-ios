//
//  HMSHLSPlayerRepresentable.swift
//  HMSRoomKitPreview
//
//  Created by Pawan Dixit on 2/15/24.
//

import SwiftUI
import AVKit
import HMSHLSPlayerSDK

internal struct HMSHLSViewRepresentable: UIViewRepresentable {
    let player: HMSHLSPlayer
    let tapBlock: (() -> Void)?
    @Binding var resetGesture: Bool
    
    init(player: HMSHLSPlayer, tapBlock: (() -> Void)?, resetGesture: Binding<Bool>) {
        self.player = player
        self.tapBlock = tapBlock
        _resetGesture = resetGesture
    }

    func makeUIView(context: Context) -> UIView {
        
        let videoViewController = player.videoPlayerViewController(showsPlayerControls: false)
        videoViewController.disableGestureRecognition()

        context.coordinator.panAndZoomController = HMSPanAndZoomController(targetView: videoViewController.view, tapBlock: {
            tapBlock?()
        })
        context.coordinator.panAndZoomController?.isZoomAndPanEnabled = true
        
        videoViewController.showsPlaybackControls = false
        videoViewController.allowsPictureInPicturePlayback = false
        videoViewController.canStartPictureInPictureAutomaticallyFromInline = false
        
        videoViewController.videoGravity = .resizeAspect
        
        AVPlayerModel.shared.currentAVPlayerInstance = videoViewController
        
        return videoViewController.view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if resetGesture {
            context.coordinator.panAndZoomController?.resetZoomAndPan()
            Task { @MainActor in
                resetGesture.toggle()
            }
        }
    }
    
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.panAndZoomController?.isZoomAndPanEnabled = false
        coordinator.panAndZoomController = nil
    }
    
    class Coordinator: NSObject {
        var parent: HMSHLSViewRepresentable
        var panAndZoomController: HMSPanAndZoomController?
        
        init(_ parent: HMSHLSViewRepresentable) {
            self.parent = parent
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

extension AVPlayerViewController {
    func disableGestureRecognition() {
        let contentView = view.value(forKey: "contentView") as? UIView
        contentView?.gestureRecognizers = contentView?.gestureRecognizers?.filter { $0 is UITapGestureRecognizer }
    }
}

extension UIView {
    func addConstrained(subview: UIView) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        subview.topAnchor.constraint(equalTo: topAnchor).isActive = true
        subview.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        subview.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        subview.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}
