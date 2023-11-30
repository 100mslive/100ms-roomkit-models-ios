//
//  HMSRoomModel+LocalUserActions.swift
//  HMSRoomKit
//
//  Created by Pawan Dixit on 06/07/2023.
//  Copyright © 2023 100ms. All rights reserved.
//

import Foundation
import HMSSDK

@MainActor
// Auth, room layout, preview, join
extension HMSRoomModel {
    public func getAuthToken(roomCode: String) async throws -> String {
        
        if let authToken = authToken {
            return authToken
        }
        else {
            return try await withCheckedThrowingContinuation({ continuation in
                
                sdk.getAuthTokenByRoomCode(roomCode, userID: userId) { authToken, error in
                    guard let authToken = authToken else {
                        continuation.resume(throwing: error!);
                        return
                    }
                    
                    self.authToken = authToken
                    continuation.resume(returning: authToken)
                }
            })
        }
    }
    
    public func getRoomLayout() async throws -> HMSRoomLayout {
        // if providedToken is nil our init constrain makes roomCode non-nil
        let authToken = providedToken != nil ? providedToken! : try await getAuthToken(roomCode: roomCode!)
        
        return try await withCheckedThrowingContinuation({ continuation in
            self.sdk.getRoomLayout(using: authToken) { roomLayout, error in
                guard let roomLayout = roomLayout else {
                    continuation.resume(throwing: error!);
                    return
                }
                
                continuation.resume(returning: roomLayout)
            }
        })
    }
    
    public func preview(userName: String? = nil) async throws {
        
        if let userName = userName {
            self.userName = userName
        }
        
        // if providedToken is nil our init constrain makes roomCode non-nil
        let authToken = providedToken != nil ? providedToken! : try await getAuthToken(roomCode: roomCode!)
        self.sdk.preview(config: HMSConfig(userName: self.userName, authToken: authToken, endpoint: UserDefaults.standard.bool(forKey: "useQAEnv") ? "https://qa-init.100ms.live/init" : nil), delegate: self)
        
        return try await withCheckedThrowingContinuation { continuation in
            
            previewCancellable = self.$isPreviewJoined.dropFirst().sink { [weak self] isPreviewJoined in
                if isPreviewJoined {
                    continuation.resume()
                    self?.previewCancellable = nil
                }
                else {
                    if let lastError = self?.lastError {
                        continuation.resume(throwing: lastError)
                        self?.previewCancellable = nil
                    }
                    else {
                        assertionFailure("last error can't be nil if preview failed")
                        continuation.resume(throwing: NSError())
                        self?.previewCancellable = nil
                    }
                }
            }
        }
    }
    
    public func joinSession(userName: String? = nil) async throws {
        
        if let userName = userName {
            self.userName = userName
        }
        
        // if providedToken is nil our init constrain makes roomCode non-nil
        let authToken = providedToken != nil ? providedToken! : try await getAuthToken(roomCode: roomCode!)
        
        self.sdk.join(config: HMSConfig(userName: self.userName, authToken: authToken, endpoint: UserDefaults.standard.bool(forKey: "useQAEnv") ? "https://qa-init.100ms.live/init" : nil), delegate: self)
        
        return try await withCheckedThrowingContinuation { continuation in
            
            joinCancellable = self.$isUserJoined.dropFirst().sink { [weak self] isUserJoined in
                if isUserJoined {
                    continuation.resume()
                    self?.joinCancellable = nil
                }
                else {
                    if let lastError = self?.lastError {
                        continuation.resume(throwing: lastError)
                        self?.joinCancellable = nil
                    }
                    else {
                        assertionFailure("last error can't be nil if join failed")
                        continuation.resume(throwing: NSError())
                        self?.joinCancellable = nil
                    }
                }
            }
        }
    }
}

// Local user actions
@MainActor
extension HMSRoomModel {
    
    // Mic and camera
    public func toggleMic() {
#if !Preview
        Task {
            if let previewAudioTrack = previewAudioTrack {
                try await previewAudioTrack.toggleMute()
            }
            else {
                try await localAudioTrackModel?.toggleMute()
            }
            
            updateLocalMuteState()
        }
#endif
    }
    public func toggleCamera() {
#if !Preview
        Task {
            if let previewVideoTrack = previewVideoTrack {
                try await previewVideoTrack.toggleMute()
            }
            else {
                try await localVideoTrackModel?.toggleMute()
            }
            
            updateLocalMuteState()
        }
#endif
    }
    
    // Leave call
    public func leaveSession() async throws {
#if !Preview
        return try await withCheckedThrowingContinuation { continuation in
            
            sdk.leave() { [weak self] success, error in
                
                guard let self else { return }
                
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    self.roomState = .leftMeeting(reason: .userLeft)
                    continuation.resume()
                }
            }
        }
#endif
    }
    
    // End session
    public func endSession(withReason reason: String = "", shouldAllowReJoin: Bool = true) async throws {
#if !Preview
        return try await withCheckedThrowingContinuation { continuation in
            
            sdk.endRoom(lock: !shouldAllowReJoin, reason: reason) { [weak self] success, error in
                
                guard let self else { return }
                
                if let error = error {
                    continuation.resume(throwing: error);
                }
                else {
                    self.roomState = .leftMeeting(reason: .roomEnded(reasonString: reason))
                    continuation.resume()
                }
            }
        }
#endif
    }
    
    // Switch camera
    public func switchCamera() async throws {
#if !Preview
        return try await withCheckedThrowingContinuation { continuation in
            (localVideoTrackModel?.track as? HMSLocalVideoTrack)?.switchCamera({ error in
                if let error = error {
                    continuation.resume(throwing: error);
                }
                else {
                    continuation.resume()
                }
            }) ?? continuation.resume()
        }
#endif
    }
    
    // Mute remote track
    public func changeTrackMuteState(for trackModel: HMSTrackModel, mute: Bool) async throws {
#if !Preview
        return try await withCheckedThrowingContinuation { continuation in
            
            sdk.changeTrackState(for: trackModel.track, mute: mute) { success, error in
                
                if let error = error {
                    continuation.resume(throwing: error);
                }
                else {
                    continuation.resume()
                }
            }
        }
#endif
    }
    
    // Kick peer out of meeting
    public func remove(peer peerModel: HMSPeerModel, withReason reason: String = "") async throws {
#if !Preview
        return try await withCheckedThrowingContinuation { continuation in
            sdk.removePeer(peerModel.peer, reason: reason) { success, error in
                if let error = error {
                    continuation.resume(throwing: error);
                }
                else {
                    continuation.resume()
                }
            }
        }
#endif
    }
    
    // Send message
    public func send(message: String, to recipient: HMSRecipient, type: String = "chat") async throws {
        
#if !Preview
        return try await withCheckedThrowingContinuation { continuation in
            
            let sendCompletion: ((HMSMessage?, Error?) -> Void) = { [weak self] newMessage, error in
                guard let self else { return }
                
                if let error = error {
                    continuation.resume(throwing: error);
                }
                else {
                    if type == "chat" {
                        if let newMessage = newMessage {
                            self.messages.append(newMessage)
                        }
                    }
                    continuation.resume()
                }
            }
            
            switch recipient {
            case .everyone:
                sdk.sendBroadcastMessage(type: type, message: message, completion: sendCompletion)
            case .role(let role):
                sdk.sendGroupMessage(type: type, message: message, roles: [role], completion: sendCompletion)
            case .peer(let peer):
                sdk.sendDirectMessage(type: type, message: message, peer: peer.peer, completion: sendCompletion)
            }
        }
#endif
    }
    

    public func switchAudioOutput(to device: HMSAudioOutputDevice) throws {
#if !Preview
        try sdk.switchAudioOutput(to: device)
#endif
    }
    
    public func startStreaming() async throws {
#if !Preview
        return try await withCheckedThrowingContinuation { continuation in
            sdk.startHLSStreaming() { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
#endif
    }
    
    public func stopStreaming() async throws {
#if !Preview
        return try await withCheckedThrowingContinuation { continuation in
            sdk.stopHLSStreaming() { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
#endif
    }
    
    public func startRecording() async throws {
#if !Preview
        return try await withCheckedThrowingContinuation { continuation in
            sdk.startRTMPOrRecording(config: HMSRTMPConfig(meetingURL: nil, rtmpURLs: nil, record: true)) { [weak self] _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    if let self = self, self.recordingState == .stopped {
                        self.recordingState = .initializing
                    }
                    continuation.resume()
                }
            }
        }
#endif
    }
    
    public func stopRecording() async throws {
#if !Preview
        return try await withCheckedThrowingContinuation { continuation in
            sdk.stopRTMPAndRecording() { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
#endif
    }
    
    public func changeUserName(to name: String) async throws {
#if !Preview
        return try await withCheckedThrowingContinuation { continuation in
            sdk.change(name: name) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
#endif
    }
    
    public func setUserMetadata(_ metadata: String) async throws {
#if !Preview
        return try await withCheckedThrowingContinuation { continuation in
            sdk.change(metadata: metadata) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
#endif
    }
    
    public func changeRole(of peer: HMSPeerModel, to role: String, shouldAskForApproval: Bool = true) async throws {
#if !Preview
        guard let destinationRole = roles.first(where: { $0.name == role }) else { return }
        
        return try await withCheckedThrowingContinuation { continuation in
            sdk.changeRole(for: peer.peer, to: destinationRole, force: !shouldAskForApproval) {_, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
#endif
    }
    
    public func previewChangeRoleRequest() async throws {
#if !Preview
        guard let request = roleChangeRequests.first else { return }
        
        return try await withCheckedThrowingContinuation { continuation in
            sdk.preview(role: request.suggestedRole) { [weak self] tracks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    tracks?.forEach {
                        if $0 is HMSAudioTrack {
                            self?.previewAudioTrack = HMSTrackModel(track: $0, peerModel: nil)
                        }
                        if $0 is HMSVideoTrack {
                            self?.previewVideoTrack = HMSTrackModel(track: $0, peerModel: nil)
                        }
                    }
                    
                    continuation.resume()
                }
            }
        }
#endif
    }
    
    public func acceptChangeRoleRequest() async throws {
#if !Preview
        guard let request = roleChangeRequests.first else { return }
        
        return try await withCheckedThrowingContinuation { continuation in
            sdk.accept(changeRole: request) { [weak self] _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    self?.roleChangeRequests.removeFirst()
                    self?.previewAudioTrack = nil
                    self?.previewVideoTrack = nil

                    continuation.resume()
                }
            }
        }
#endif
    }
    
    public func declineChangeRoleRequest() async throws {
#if !Preview
        guard roleChangeRequests.first != nil else { return }
        previewAudioTrack = nil
        previewVideoTrack = nil
        sdk.cancelPreview()
        
        roleChangeRequests.removeFirst()
#endif
    }
    
    public func raiseHand() async throws {
#if !Preview
        return try await withCheckedThrowingContinuation { continuation in
            sdk.raiseLocalPeerHand() { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
#endif
    }
    
    
    public func lowerHand() async throws {
#if !Preview
        return try await withCheckedThrowingContinuation { continuation in
            sdk.lowerLocalPeerHand() { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
#endif
    }
    
    public func lowerHand(of peer: HMSPeerModel) async throws {
#if !Preview
        if peer.isLocal {
            try await lowerHand()
        }
        else {
            return try await withCheckedThrowingContinuation { continuation in
                sdk.lowerRemotePeerHand(peer.peer) { _, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
#endif
    }

    public func getPeerListIterator(for roleName: String, limit: Int = 10) -> HMSPeerListIteratorModel {
        let iterator = HMSPeerListIteratorModel(iterator: sdk.getPeerListIterator(options: HMSPeerListIteratorOptions(filterByRoleName: roleName, limit: limit))) { [weak self] inPeer in
#if !Preview
            HMSPeerModel(peer: inPeer, roomModel: self)
#else
            HMSPeerModel()
#endif
        }
        return iterator
    }
    
    public func beginObserving(keys: [String]) {
        sharedSessionStore.beginObserving(keys: keys)
    }
    
    public func stopObserving(keys: [String]) {
        sharedSessionStore.stopObserving(keys: keys)
    }
}
