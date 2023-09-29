//
//  HMSRoomModelExtension.swift
//  HMSRoomKit
//
//  Created by Pawan Dixit on 27/06/2023.
//  Copyright © 2023 100ms. All rights reserved.
//

import SwiftUI
import HMSSDK

@MainActor
extension HMSRoomModel {
    func insert(peer: HMSPeer) {
#if !Preview
        let peerModel = HMSPeerModel(peer: peer, roomModel: self)
        
        if peer.isLocal {
            if let previewAudioTrack = previewAudioTrack {
                peerModel.insert(track: previewAudioTrack.track)
                self.previewAudioTrack = nil
            }
            if let previewVideoTrack = previewVideoTrack {
                peerModel.insert(track: previewVideoTrack.track)
                self.previewVideoTrack = nil
            }
        }
        
        if !peerModels.contains(peerModel) {
            peerModels.append(peerModel)
        }
        else {
            // replace
            if let index = peerModels.firstIndex(of: peerModel) {
                peerModels[index] = peerModel
            }
        }
        
        if peer.isLocal {
            updateLocalMuteState()
            updateLocalRole()
        }
        #endif
    }
    
    func remove(peer: HMSPeer) {
#if !Preview
        peerModels.removeAll{$0.peer == peer}
        didChangeScreenSharingState(for:  HMSPeerModel(peer: peer, roomModel: self), state: .removed)
        #endif
    }
    
    func updateLocalMuteState() {
        isMicMute = localAudioTrackModel?.isMute ?? true
        isCameraMute = localVideoTrackModel?.isMute ?? true
    }
    
    func updateLocalRole() {
#if !Preview
        userRole = localPeerModel?.role
        #endif
    }
    
    func updateLocalUserName() {
        if let localPeerModel = localPeerModel {
            userName = localPeerModel.name
        }
    }
}

// Update screen sharing
@MainActor
extension HMSRoomModel {
    enum PeerStateChange {
        case removed
        case updated
    }
    func didChangeScreenSharingState(for peer: HMSPeerModel, state: PeerStateChange) {
        switch state {
        case .removed:
            if peer.isLocal {
                isUserSharingScreen = false
            }
            peersSharingScreen.removeAll{$0 == peer}
        case .updated:
            if peer.screenTrackModels.count > 0 {
                if !peersSharingScreen.contains(peer) {
                    if peer.isLocal {
                        isUserSharingScreen = true
                    }
                    peersSharingScreen.append(peer)
                }
            }
            else {
                if peer.isLocal {
                    isUserSharingScreen = false
                }
                peersSharingScreen.removeAll{$0 == peer}
            }
        }
    }
}

// Room updates
@MainActor
extension HMSRoomModel {
    
    func assign(room: HMSRoom) {
        self.room = room
        updateMetadata()
        updateRecordingState()
        updateStreamingState()
    }
    
    func updateMetadata() {
        guard let room = room else { assertionFailure("shouldn't be here"); return }
        roomID = room.roomID
        name = room.name
        sessionID = room.sessionID
        sessionStartedAt = room.sessionStartedAt
    }
    
    func updateRecordingState() {
        guard let room = room else { assertionFailure("shouldn't be here"); return }
        if room.browserRecordingState.initialising {
            recordingState = .initializing
        } else if room.browserRecordingState.running || room.serverRecordingState.running || room.hlsRecordingState.running {
            recordingState = .recording
        } else {
            if room.browserRecordingState.error != nil || room.hlsRecordingState.error != nil {
                recordingState = .failed
            }
            else {
                recordingState = .stopped
            }
        }
    }
    
    func updateStreamingState() {
        guard let room = room else { assertionFailure("shouldn't be here"); return }
        
        isBeingStreamed = room.rtmpStreamingState.running || room.hlsStreamingState.running
        hlsVariants = room.hlsStreamingState.variants
    }
}

// Peer updates
@MainActor
extension HMSRoomModel {
    func updateRole(for peer: HMSPeer) {
#if !Preview
        guard let peerModel = (peerModels.first{$0.peer == peer}) else { return }
        peerModel.updateRole()
        
        if peerModel.isLocal {
            updateLocalRole()
        }
        #endif
    }
    
    func updateName(for peer: HMSPeer) {
#if !Preview
        guard let peerModel = (peerModels.first{$0.peer == peer}) else { return }
        peerModel.updateName()
        
        if peerModel.isLocal {
            updateLocalUserName()
        }
        #endif
    }
    
    func updateHandRaise(for peer: HMSPeer) {
#if !Preview
        guard let peerModel = (peerModels.first{$0.peer == peer}) else { return }
        peerModel.updateHandRaise()
        #endif
    }
    
    func updateMetadata(for peer: HMSPeer) {
#if !Preview
        guard let peerModel = (peerModels.first{$0.peer == peer}) else { return }
        peerModel.updateMetadata()
        #endif
    }
    
    func updateNetworkQuality(for peer: HMSPeer) {
#if !Preview
        guard let peerModel = (peerModels.first{$0.peer == peer}) else { return }
        peerModel.updateDownlinkQuality()
        #endif
    }
}
