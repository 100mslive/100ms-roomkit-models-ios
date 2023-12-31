//
//  HMSRoomModelExtension.swift
//  HMSRoomKit
//
//  Created by Pawan Dixit on 27/06/2023.
//  Copyright © 2023 100ms. All rights reserved.
//

import SwiftUI
import HMSSDK

// Convenience computed properties
@MainActor
extension HMSRoomModel {
    
    #if !Preview
    public var localAudioTrackModel: HMSTrackModel? {
        
        if let previewAudioTrack = previewAudioTrack {
            return previewAudioTrack
        }
        
        guard let localTrackModels = localPeerModel?.trackModels else { return nil }
        
        guard let index = localTrackModels.firstIndex(where: { $0.track is HMSLocalAudioTrack }) else { return nil }
        
        return localTrackModels[index]
    }
    
    public var localVideoTrackModel: HMSTrackModel? {
        
        if let previewVideoTrack = previewVideoTrack {
            return previewVideoTrack
        }
        
        guard let localTrackModels = localPeerModel?.trackModels else { return nil }
        
        guard let index = localTrackModels.firstIndex(where: { $0.track is HMSLocalVideoTrack }) else { return nil }
        
        return localTrackModels[index]
    }
    #endif
}
