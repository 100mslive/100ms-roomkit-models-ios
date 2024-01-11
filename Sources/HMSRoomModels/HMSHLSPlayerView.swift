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
import SwiftUIIntrospect

import AVKit

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
    
    @EnvironmentObject var roomModel: HMSRoomModel
    
    @StateObject var coordinator = Coordinator()

    let url: URL?
    
    var onCue: ((HMSHLSCue)->Void)?
    var onPlaybackFailure: ((Error)->Void)?
    var onPlaybackStateChanged: ((HMSHLSPlaybackState)->Void)?
    var onResolutionChanged: ((CGSize)->Void)?
    
    
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
        VideoPlayer(player: coordinator.player._nativePlayer, videoOverlay: {
            videoOverlay?(coordinator.player)
        })
        .introspect(.videoPlayer, on: .iOS(.v14, .v15, .v16, .v17)) {
            $0.showsPlaybackControls = false
            $0.allowsPictureInPicturePlayback = false
            $0.canStartPictureInPictureAutomaticallyFromInline = false
            $0.videoGravity = .resizeAspectFill
            AVPlayerModel.shared.currentAVPlayerInstance = $0
        }
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
