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

@MainActor
class AVPlayerModel {
    static let shared = AVPlayerModel()
    weak var currentAVPlayerInstance: AVPlayerViewController?
}

public struct HMSPlayerConstants {
    static let seekBarPadding: CGFloat = 4
    
    public static func preferredHeight(for width: CGFloat) -> CGFloat {
        return (width * 9) / 16 + HMSPlayerConstants.seekBarPadding
    }
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
    
    var hideControlsTask: Task<(), any Error> {
        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            hlsPlayerPreferences.isControlsHidden.wrappedValue = true
        }
    }
    
    public init(url: URL? = nil, resetGesture: Binding<Bool>, @ViewBuilder videoOverlay: @escaping (HMSHLSPlayer) -> VideoOverlay) {
        self.videoOverlay = videoOverlay
        self.url = url
        _resetGesture = resetGesture
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
    
    @Binding var resetGesture: Bool
    
    func videoView(url: URL) -> some View {
        VStack {
            GeometryReader { geo in
                ZStack {
                    HMSHLSViewRepresentable(player: coordinator.player, tapBlock: {
                        hlsPlayerPreferences.isControlsHidden.wrappedValue.toggle()
                        
                        if !hlsPlayerPreferences.isControlsHidden.wrappedValue {
                            hideTasks.append(hideControlsTask)
                        }
                        else {
                            hideTasks.forEach{$0.cancel()}
                            hideTasks.removeAll()
                        }
                        
                        // hide keyboard it it's present
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }, resetGesture: $resetGesture)
                    .frame(width: geo.size.width, height: geo.size.height )
                    .onAppear() {
                        hideTasks.append(hideControlsTask)
                        
                        hlsPlayerPreferences.resetHideTask.wrappedValue = {
                            hideTasks.forEach{$0.cancel()}
                            hideTasks.removeAll()
                            hideTasks.append(hideControlsTask)
                        }
                    }
                    .onChange(of: hlsPlayerPreferences.isControlsHidden.wrappedValue) { isControlsHidden in
                        
                        hideTasks.forEach{$0.cancel()}
                        hideTasks.removeAll()
                        
                        if !isControlsHidden {
                            hideTasks.append(hideControlsTask)
                        }
                    }
                }
            }
            Spacer().frame(height: HMSPlayerConstants.seekBarPadding)
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
    
    public func onCue(cue: @escaping (HMSHLSCue)->Void) -> HMSHLSPlayerView {
        var newView = HMSHLSPlayerView(url: url, resetGesture: $resetGesture, videoOverlay: videoOverlay!)
        setupNewView(newView: &newView)
        newView.onCue = { value in
            cue(value)
        }
        return newView
    }
    public func onPlaybackFailure(error: @escaping (Error)->Void) -> HMSHLSPlayerView {
        var newView = HMSHLSPlayerView(url: url, resetGesture: $resetGesture, videoOverlay: videoOverlay!)
        setupNewView(newView: &newView)
        newView.onPlaybackFailure = { value in
            error(value)
        }
        return newView
    }
    public func onPlaybackStateChanged(state: @escaping (HMSHLSPlaybackState)->Void) -> HMSHLSPlayerView {
        var newView = HMSHLSPlayerView(url: url, resetGesture: $resetGesture, videoOverlay: videoOverlay!)
        setupNewView(newView: &newView)
        newView.onPlaybackStateChanged = { value in
            state(value)
        }
        return newView
    }
    public func onResolutionChanged(videoSize: @escaping (CGSize)->Void) -> HMSHLSPlayerView {
        var newView = HMSHLSPlayerView(url: url, resetGesture: $resetGesture, videoOverlay: videoOverlay!)
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
    public init(url: URL? = nil, resetGesture: Binding<Bool>) {
        videoOverlay = nil
        self.url = url
        _resetGesture = resetGesture
    }
    
    public func onCue(cue: @escaping (HMSHLSCue)->Void) -> HMSHLSPlayerView {
        var newView = HMSHLSPlayerView(url: url, resetGesture: $resetGesture)
        setupNewView(newView: &newView)
        newView.onCue = { value in
            cue(value)
        }
        return newView
    }
    public func onPlaybackFailure(error: @escaping (Error)->Void) -> HMSHLSPlayerView {
        var newView = HMSHLSPlayerView(url: url, resetGesture: $resetGesture)
        setupNewView(newView: &newView)
        newView.onPlaybackFailure = { value in
            error(value)
        }
        return newView
    }
    public func onPlaybackStateChanged(state: @escaping (HMSHLSPlaybackState)->Void) -> HMSHLSPlayerView {
        var newView = HMSHLSPlayerView(url: url, resetGesture: $resetGesture)
        setupNewView(newView: &newView)
        newView.onPlaybackStateChanged = { value in
            state(value)
        }
        return newView
    }
    public func onResolutionChanged(videoSize: @escaping (CGSize)->Void) -> HMSHLSPlayerView {
        var newView = HMSHLSPlayerView(url: url, resetGesture: $resetGesture)
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
        HMSHLSPlayerView(resetGesture: .constant(false))
            .environmentObject(HMSUITheme())
#endif
    }
}
