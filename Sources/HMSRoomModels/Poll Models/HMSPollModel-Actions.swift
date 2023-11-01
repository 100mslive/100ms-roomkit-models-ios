//
//  HMSPollModel-Actions.swift
//  HMSRoomKitPreview
//
//  Created by Pawan Dixit on 11/1/23.
//

import SwiftUI
import HMSSDK

@MainActor
extension HMSPollModel {
    
    public func addQuestion(_ question: HMSPollQuestion) async throws {
        
        return try await withCheckedThrowingContinuation { continuation in
            roomModel?.sdk.interactivityCenter.setPollQuestions(poll: self.poll, questions: (self.questions ?? []) + [question], completion: { success, error in
                
                if let error = error {
                    continuation.resume(throwing: error);
                }
                else {
                    continuation.resume()
                }
            })
        }
    }
}
