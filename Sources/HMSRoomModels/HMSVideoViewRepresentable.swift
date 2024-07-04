//
//  HMSVideoViewRepresentable.swift
//  HMSUIKit
//
//  Created by Pawan Dixit on 29/05/2023.
//

import SwiftUI
import HMSSDK

public struct HMSVideoTrackView: View {
    
    @ObservedObject var peer: HMSPeerModel
    var contentMode: UIView.ContentMode
    let unsubscribeWhenOffscreen: Bool
    
    public init(peer: HMSPeerModel, contentMode: UIView.ContentMode = .scaleAspectFill, unsubscribeWhenOffscreen: Bool = false) {
        self.peer = peer
        self.contentMode = contentMode
        self.unsubscribeWhenOffscreen = unsubscribeWhenOffscreen
    }
    
    public var body: some View {
        if let regularVideoTrackModel = peer.regularVideoTrackModel {
            HMSTrackView(track: regularVideoTrackModel, contentMode: contentMode, isZoomAndPanEnabled: false, unsubscribeWhenOffscreen: unsubscribeWhenOffscreen)
        }
    }
}

public struct HMSScreenTrackView: View {
    
    @ObservedObject var peer: HMSPeerModel
    var contentMode: UIView.ContentMode
    var isZoomAndPanEnabled: Bool
    let unsubscribeWhenOffscreen: Bool
    
    public init(peer: HMSPeerModel, contentMode: UIView.ContentMode = .scaleAspectFit, isZoomAndPanEnabled: Bool = true, unsubscribeWhenOffscreen: Bool = false) {
        self.peer = peer
        self.contentMode = contentMode
        self.isZoomAndPanEnabled = isZoomAndPanEnabled
        self.unsubscribeWhenOffscreen = unsubscribeWhenOffscreen
    }
    
    public var body: some View {
        if let screenVideoTrackModel = peer.screenVideoTrackModel {
            HMSTrackView(track: screenVideoTrackModel, contentMode: contentMode, isZoomAndPanEnabled: isZoomAndPanEnabled, unsubscribeWhenOffscreen: unsubscribeWhenOffscreen)
        }
    }
}

public struct HMSTrackView: View {
    
    @ObservedObject var track: HMSTrackModel
    var contentMode: UIView.ContentMode
    var isZoomAndPanEnabled: Bool
    let unsubscribeWhenOffscreen: Bool
    
    @StateObject private var viewState = HMSVideoViewRepresentable.ViewState()
    
    public init(track: HMSTrackModel, contentMode: UIView.ContentMode, isZoomAndPanEnabled: Bool, unsubscribeWhenOffscreen: Bool = false) {
        self.track = track
        self.contentMode = contentMode
        self.isZoomAndPanEnabled = isZoomAndPanEnabled
        self.unsubscribeWhenOffscreen = unsubscribeWhenOffscreen
    }
    
    public var body: some View {
        if let videoTrack = track.track as? HMSVideoTrack {
            
            if unsubscribeWhenOffscreen {
                HMSVideoViewRepresentable(track: videoTrack, contentMode: contentMode, isZoomAndPanEnabled: isZoomAndPanEnabled, viewState: viewState)
                    .onAppear() {
                        viewState.isOnScreen = true
                    }
                    .onDisappear() {
                        viewState.isOnScreen = false
                    }
            }
            else {
                HMSVideoViewRepresentable(track: videoTrack, contentMode: contentMode, isZoomAndPanEnabled: isZoomAndPanEnabled, viewState: viewState)
            }
        }
    }
}

internal struct HMSVideoViewRepresentable: UIViewRepresentable {
    
    internal class ViewState: ObservableObject {
        @Published var isOnScreen: Bool = false
    }
    
    var track: HMSVideoTrack
    var contentMode: UIView.ContentMode
    var isZoomAndPanEnabled: Bool
    
    @ObservedObject var viewState: ViewState
    
    init(track: HMSVideoTrack, contentMode: UIView.ContentMode = .scaleAspectFit, isZoomAndPanEnabled: Bool = false, viewState: ViewState) {
        self.track = track
        self.contentMode = contentMode
        self.isZoomAndPanEnabled = isZoomAndPanEnabled
        self._viewState = ObservedObject(initialValue: viewState)
    }

    func makeUIView(context: Context) -> HMSVideoView {

        let videoView = HMSVideoView()
        videoView.setVideoTrack(track)
        videoView.videoContentMode = contentMode
        videoView.isZoomAndPanEnabled = isZoomAndPanEnabled
        return videoView
    }

    func updateUIView(_ videoView: HMSVideoView, context: Context) {
        if viewState.isOnScreen {
            onAppear(videoView, context: context)
        } else {
            onDisappear(videoView, context: context)
        }
    }
    
    static func dismantleUIView(_ uiView: HMSVideoView, coordinator: ()) {
        uiView.setVideoTrack(nil)
    }
    
    func onAppear(_ videoView: HMSVideoView, context: Context) {
        videoView.setVideoTrack(track)
    }
    
    func onDisappear(_ videoView: HMSVideoView, context: Context) {
        videoView.setVideoTrack(nil)
    }
}
