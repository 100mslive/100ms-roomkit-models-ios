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

extension HMSRoomModel {
    
    public var localPeerModel: HMSPeerModel? {
        peerModels.first{$0.isLocal}
    }
    
    public var remotePeerModels: [HMSPeerModel] {
        peerModels.filter{!$0.isLocal}
    }
    
    public var remotePeersSharingScreen: [HMSPeerModel] {
        peersSharingScreen.filter{!$0.isLocal}
    }
    
    public var userCanStartStopHLSStream: Bool {
        localPeerModel?.canStartStopHLSStream ?? false
    }
    public var userCanStartStopRecording: Bool {
        localPeerModel?.canStartStopRecording ?? false
    }
    public var userCanShareScreen: Bool {
        localPeerModel?.canScreenShare ?? false
    }
    
    public var remotePeerModelsExcludingViewers: [HMSPeerModel] {
#if !Preview
        remotePeerModels.filter{$0.role?.canPublish ?? false}
#else
        remotePeerModels
#endif
    }
}

public enum HMSTranscriptionMode: String {
    case caption
}

public extension [HMSTranscriptionState] {
    
    func stateWith(mode: HMSTranscriptionMode) -> HMSTranscriptionState? {
        self.first{$0.mode == mode.rawValue}
    }
}

public extension [HMSTranscriptionPermissions] {
    
    func permissionWith(mode: HMSTranscriptionMode) -> HMSTranscriptionPermissions? {
        self.first{$0.mode == mode.rawValue}
    }
}
