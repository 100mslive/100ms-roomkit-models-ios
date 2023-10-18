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
    
    public init(peer: HMSPeerModel, contentMode: UIView.ContentMode = .scaleAspectFill) {
        self.peer = peer
        self.contentMode = contentMode
    }
    
    public var body: some View {
        if let regularVideoTrackModel = peer.regularVideoTrackModel {
            HMSTrackView(track: regularVideoTrackModel, contentMode: contentMode, isZoomAndPanEnabled: false)
        }
    }
}

public struct HMSScreenTrackView: View {
    
    @ObservedObject var peer: HMSPeerModel
    var contentMode: UIView.ContentMode
    var isZoomAndPanEnabled: Bool
    
    public init(peer: HMSPeerModel, contentMode: UIView.ContentMode = .scaleAspectFit, isZoomAndPanEnabled: Bool = true) {
        self.peer = peer
        self.contentMode = contentMode
        self.isZoomAndPanEnabled = isZoomAndPanEnabled
    }
    
    public var body: some View {
        if let screenVideoTrackModel = peer.screenVideoTrackModel {
            HMSTrackView(track: screenVideoTrackModel, contentMode: contentMode, isZoomAndPanEnabled: isZoomAndPanEnabled)
        }
    }
}

public struct HMSTrackView: View {
    
    @ObservedObject var track: HMSTrackModel
    var contentMode: UIView.ContentMode
    var isZoomAndPanEnabled: Bool
    
    public init(track: HMSTrackModel, contentMode: UIView.ContentMode, isZoomAndPanEnabled: Bool) {
        self.track = track
        self.contentMode = contentMode
        self.isZoomAndPanEnabled = isZoomAndPanEnabled
    }
    
    public var body: some View {
        if let videoTrack = track.track as? HMSVideoTrack {
            HMSVideoViewRepresentable(track: videoTrack, contentMode: contentMode, isZoomAndPanEnabled: isZoomAndPanEnabled)
        }
    }
}

internal struct HMSVideoViewRepresentable: UIViewRepresentable {
    var track: HMSVideoTrack
    var contentMode: UIView.ContentMode
    var isZoomAndPanEnabled: Bool
    
    init(track: HMSVideoTrack, contentMode: UIView.ContentMode = .scaleAspectFit, isZoomAndPanEnabled: Bool = false) {
        self.track = track
        self.contentMode = contentMode
        self.isZoomAndPanEnabled = isZoomAndPanEnabled
    }

    func makeUIView(context: Context) -> HMSVideoView {

        let videoView = HMSVideoView()
        videoView.setVideoTrack(track)
        videoView.videoContentMode = contentMode
        videoView.isZoomAndPanEnabled = isZoomAndPanEnabled
        return videoView
    }

    func updateUIView(_ videoView: HMSVideoView, context: Context) {}
    
    static func dismantleUIView(_ uiView: HMSVideoView, coordinator: ()) {
        uiView.setVideoTrack(nil)
    }
}
