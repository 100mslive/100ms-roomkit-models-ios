//
//  HMSPeerModelExtension.swift
//  HMSRoomKit
//
//  Created by Pawan Dixit on 27/06/2023.
//  Copyright © 2023 100ms. All rights reserved.
//

import SwiftUI
import HMSSDK

extension [HMSPeerModel] {
    public func filter(withRoles roles: [String]) -> [HMSPeerModel] {
        self.filter{
            if let role = $0.role {
                return roles.contains(role.name)
            }
            else {
                return false
            }
        }
    }
}

// Convenience computed properties
extension HMSPeerModel {
    #if !Preview
    public var audioTrackModels: [HMSTrackModel] {
        trackModels.filter{$0.track is HMSAudioTrack}
    }
    public var regularVideoTrackModels: [HMSTrackModel] {
        trackModels.filter{$0.track is HMSVideoTrack && $0.track.source == HMSCommonTrackSource.regular}
    }
    public var screenTrackModels: [HMSTrackModel] {
        trackModels.filter{$0.track is HMSVideoTrack && $0.track.source == HMSCommonTrackSource.screen}
    }
    public var isSharingScreen: Bool {
        trackModels.contains{$0.track.source == HMSCommonTrackSource.screen}
    }
    #endif
}

// Mute and unmute
extension HMSPeerModel {
    func mute(track: HMSTrack) {
#if !Preview
        if let index = trackModels.firstIndex(where: {$0.track == track}) {
            trackModels[index].isMute = true
        }
#endif
    }
    func unmute(track: HMSTrack) {
#if !Preview
        if let index = trackModels.firstIndex(where: {$0.track == track}) {
            trackModels[index].isMute = false
        }
#endif
    }
}
