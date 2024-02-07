//
//  HMSHLSPlayerView.swift
//  HMSSDK
//
//  Created by Pawan Dixit on 27/07/2023.
//  Copyright © 2023 100ms. All rights reserved.
//

import SwiftUI
import HMSSDK
import HMSHLSPlayerSDK

import AVKit

public struct HMSHLSPreferences {
    
    public var isControlsHidden = false
    public var resetHideTask: (() -> Void)?
    
    public init(isControlsHidden: Bool = false, resetHideTask: (() -> Void)? = nil) {
        self.isControlsHidden = isControlsHidden
        self.resetHideTask = resetHideTask
    }
    
    struct Key: EnvironmentKey {
        static let defaultValue: Binding<HMSHLSPreferences> = .constant(.init(isControlsHidden: false))
    }
}

public extension EnvironmentValues {
    
    var hlsPlayerPreferences: Binding<HMSHLSPreferences> {
        get { self[HMSHLSPreferences.Key.self] }
        set { self[HMSHLSPreferences.Key.self] = newValue }
    }
}

@MainActor
class AVPlayerModel {
    static let shared = AVPlayerModel()
    weak var currentAVPlayerInstance: AVPlayerViewController?
}

public struct HMSHLSPlayerView<VideoOverlay> : View where VideoOverlay : View {
    
    class Coordinator: HMSHLSPlayerDelegate, ObservableObject {
        
        let player = HMSHLSPlayer()
        
        init() {
            player.delegate = self
            player._nativePlayer.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
        }
        
        var onCue: ((HMSHLSCue)->Void)?
        var onPlaybackFailure: ((Error)->Void)?
        var onPlaybackStateChanged: ((HMSHLSPlaybackState)->Void)?
        var onResolutionChanged: ((CGSize)->Void)?
        
        func onCue(cue: HMSHLSCue) {
            onCue?(cue)
        }
        func onPlaybackFailure(error: Error) {
            onPlaybackFailure?(error)
        }
        func onPlaybackStateChanged(state: HMSHLSPlaybackState) {
            onPlaybackStateChanged?(state)
        }
        func onResolutionChanged(videoSize: CGSize) {
            onResolutionChanged?(videoSize)
            Task { @MainActor in
                if videoSize.width > videoSize.height {
                    AVPlayerModel.shared.currentAVPlayerInstance?.videoGravity = .resizeAspect
                }
                else {
                    AVPlayerModel.shared.currentAVPlayerInstance?.videoGravity = .resizeAspectFill
                }
            }
        }
    }
    
    @Environment(\.hlsPlayerPreferences) var hlsPlayerPreferences
    @EnvironmentObject var roomModel: HMSRoomModel
    
    @StateObject var coordinator = Coordinator()
    
    let url: URL?
    
    var onCue: ((HMSHLSCue)->Void)?
    var onPlaybackFailure: ((Error)->Void)?
    var onPlaybackStateChanged: ((HMSHLSPlaybackState)->Void)?
    var onResolutionChanged: ((CGSize)->Void)?
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScaleValue: CGFloat = 1.0
    
    @State var hideTasks = [Task<(), any Error>]()
    
    @State private var currentOffset = CGSize.zero // Current position offset
    @State private var dragOffset = CGSize.zero // Offset while dragging
    
    @ViewBuilder let videoOverlay: ((HMSHLSPlayer) -> VideoOverlay)?
    public init(url: URL? = nil, @ViewBuilder videoOverlay: @escaping (HMSHLSPlayer) -> VideoOverlay) {
        self.videoOverlay = videoOverlay
        self.url = url
    }
    
    public var body: some View {
        Group {
            if let url = url {
                videoView(url: url)
            }
            else if let url = roomModel.hlsVariants.first?.url {
                videoView(url: url)
            }
        }
        .onAppear() {
            coordinator.onCue = onCue
            coordinator.onPlaybackFailure = onPlaybackFailure
            coordinator.onPlaybackStateChanged = onPlaybackStateChanged
            coordinator.onResolutionChanged = onResolutionChanged
            coordinator.player.analytics = roomModel.sdk
        }
    }
    
    func videoView(url: URL) -> some View {
        GeometryReader { geo in
            
            ZStack {
                HMSHLSViewRepresentable(player: coordinator.player, tapBlock: {
                    hlsPlayerPreferences.isControlsHidden.wrappedValue.toggle()
                    
                    if !hlsPlayerPreferences.isControlsHidden.wrappedValue {
                        let task = Task {
                            try await Task.sleep(nanoseconds: 3_000_000_000)
                            hlsPlayerPreferences.isControlsHidden.wrappedValue = true
                        }
                        hideTasks.append(task)
                    }
                    else {
                        hideTasks.forEach{$0.cancel()}
                        hideTasks.removeAll()
                    }
                    
                    // hide keyboard it it's present
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                })
                    .frame(width: geo.size.width, height: geo.size.height )
                    .onAppear() {
                        let task = Task {
                            try await Task.sleep(nanoseconds: 3_000_000_000)
                            hlsPlayerPreferences.isControlsHidden.wrappedValue = false
                        }
                        hideTasks.append(task)
                        
                        hlsPlayerPreferences.resetHideTask.wrappedValue = {
                            hideTasks.forEach{$0.cancel()}
                            hideTasks.removeAll()
                            
                            let task = Task {
                                try await Task.sleep(nanoseconds: 3_000_000_000)
                                hlsPlayerPreferences.isControlsHidden.wrappedValue = false
                            }
                            hideTasks.append(task)
                        }
                    }
                    .onChange(of: hlsPlayerPreferences.isControlsHidden.wrappedValue) { isControlsHidden in
                        
                        hideTasks.forEach{$0.cancel()}
                        hideTasks.removeAll()
                        
                        if !isControlsHidden {
                            let task = Task {
                                try await Task.sleep(nanoseconds: 3_000_000_000)
                                hlsPlayerPreferences.isControlsHidden.wrappedValue = false
                            }
                            hideTasks.append(task)
                        }
                    }
            }
        }
        .overlay(content: {
            videoOverlay?(coordinator.player)
        })
        .onAppear() {
            coordinator.player.play(url)
        }
        .onDisappear() {
            coordinator.player.stop()
        }
        
        .onChange(of: roomModel.hlsVariants) { variant in
            if self.url == nil {
                if let url = variant.first?.url {
                    coordinator.player.play(url)
                }
            }
        }
    }
    
    private func dragChanged(value: DragGesture.Value?, geo: GeometryProxy) {
        
        let maxDragDistanceX = geo.size.width * scale - geo.size.width
        let maxDragDistanceY = geo.size.height * scale - geo.size.height
        
        // Calculate and constrain the drag offset
        let dragX = max(min((value?.translation.width ?? 0) + currentOffset.width, maxDragDistanceX), -maxDragDistanceX)
        let dragY = max(min((value?.translation.height ?? 0) + currentOffset.height, maxDragDistanceY), -maxDragDistanceY)
        
        var x = dragX - currentOffset.width
        var y = dragY - currentOffset.height
        
        if currentOffset.width + x > 0 {
            x = self.dragOffset.width
        }
        if currentOffset.height + y > 0 {
            y = self.dragOffset.height
        }
        
        self.dragOffset = CGSize(width: x, height: y)
    }
    
    public func onCue(cue: @escaping (HMSHLSCue)->Void) -> HMSHLSPlayerView {
        var newView = HMSHLSPlayerView(url: url, videoOverlay: videoOverlay!)
        setupNewView(newView: &newView)
        newView.onCue = { value in
            cue(value)
        }
        return newView
    }
    public func onPlaybackFailure(error: @escaping (Error)->Void) -> HMSHLSPlayerView {
        var newView = HMSHLSPlayerView(url: url, videoOverlay: videoOverlay!)
        setupNewView(newView: &newView)
        newView.onPlaybackFailure = { value in
            error(value)
        }
        return newView
    }
    public func onPlaybackStateChanged(state: @escaping (HMSHLSPlaybackState)->Void) -> HMSHLSPlayerView {
        var newView = HMSHLSPlayerView(url: url, videoOverlay: videoOverlay!)
        setupNewView(newView: &newView)
        newView.onPlaybackStateChanged = { value in
            state(value)
        }
        return newView
    }
    public func onResolutionChanged(videoSize: @escaping (CGSize)->Void) -> HMSHLSPlayerView {
        var newView = HMSHLSPlayerView(url: url, videoOverlay: videoOverlay!)
        setupNewView(newView: &newView)
        newView.onResolutionChanged = { value in
            videoSize(value)
        }
        return newView
    }
    
    private func setupNewView( newView: inout HMSHLSPlayerView) {
        
        newView.onCue = onCue
        newView.onPlaybackFailure = onPlaybackFailure
        newView.onPlaybackStateChanged = onPlaybackStateChanged
        newView.onResolutionChanged = onResolutionChanged
    }
}

extension HMSHLSPlayerView where VideoOverlay == EmptyView {
    public init(url: URL? = nil) {
        videoOverlay = nil
        self.url = url
    }
    
    public func onCue(cue: @escaping (HMSHLSCue)->Void) -> HMSHLSPlayerView {
        var newView = HMSHLSPlayerView(url: url)
        setupNewView(newView: &newView)
        newView.onCue = { value in
            cue(value)
        }
        return newView
    }
    public func onPlaybackFailure(error: @escaping (Error)->Void) -> HMSHLSPlayerView {
        var newView = HMSHLSPlayerView(url: url)
        setupNewView(newView: &newView)
        newView.onPlaybackFailure = { value in
            error(value)
        }
        return newView
    }
    public func onPlaybackStateChanged(state: @escaping (HMSHLSPlaybackState)->Void) -> HMSHLSPlayerView {
        var newView = HMSHLSPlayerView(url: url)
        setupNewView(newView: &newView)
        newView.onPlaybackStateChanged = { value in
            state(value)
        }
        return newView
    }
    public func onResolutionChanged(videoSize: @escaping (CGSize)->Void) -> HMSHLSPlayerView {
        var newView = HMSHLSPlayerView(url: url)
        setupNewView(newView: &newView)
        newView.onResolutionChanged = { value in
            videoSize(value)
        }
        return newView
    }
}

struct HMSHLSPlayerView_Previews: PreviewProvider {
    static var previews: some View {
#if Preview
        HMSHLSPlayerView()
            .environmentObject(HMSUITheme())
#endif
    }
}

internal struct HMSHLSViewRepresentable: UIViewRepresentable {
    let player: HMSHLSPlayer
    let tapBlock: (() -> Void)?
    
    init(player: HMSHLSPlayer, tapBlock: (() -> Void)?) {
        self.player = player
        self.tapBlock = tapBlock
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
        
        AVPlayerModel.shared.currentAVPlayerInstance = videoViewController
        
        return videoViewController.view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
    
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
