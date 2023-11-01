//
//  HMSRoomModel-Polls.swift
//  HMSRoomKitPreview
//
//  Created by Pawan Dixit on 10/31/23.
//

import SwiftUI
import HMSSDK

public extension HMSRoomModel {
    
    func createPoll(_ poll: HMSPollModel) async throws {
        
        return try await withCheckedThrowingContinuation { continuation in
            sdk.interactivityCenter.create(poll: poll.poll) { success, error in
                
                if let error = error {
                    continuation.resume(throwing: error);
                }
                else {
                    continuation.resume()
                }
            }
        }
    }
    
    func startPoll(_ poll: HMSPollModel) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            sdk.interactivityCenter.start(poll: poll.poll) { success, error in
                
                if let error = error {
                    continuation.resume(throwing: error);
                }
                else {
                    continuation.resume()
                }
            }
        }
    }
    
    func finishPoll(_ poll: HMSPollModel) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            sdk.interactivityCenter.stop(poll: poll.poll) { success, error in
                
                if let error = error {
                    continuation.resume(throwing: error);
                }
                else {
                    continuation.resume()
                }
            }
        }
    }
}
