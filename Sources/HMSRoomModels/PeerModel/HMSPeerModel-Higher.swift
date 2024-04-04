//
//  HMSPeerModelExtension.swift
//  HMSRoomKit
//
//  Created by Pawan Dixit on 27/06/2023.
//  Copyright © 2023 100ms. All rights reserved.
//

import SwiftUI

extension HMSPeerModel {
    public var regularAudioTrackModel: HMSTrackModel? {
        audioTrackModels.first
    }
    public var regularVideoTrackModel: HMSTrackModel? {
        regularVideoTrackModels.first
    }
    public var screenVideoTrackModel: HMSTrackModel? {
        screenTrackModels.first
    }
    public func recentTranscript(within timeInterval: TimeInterval) -> [HMSPeerModel.Transcript] {
        transcript.filter {
            Date().timeIntervalSince($0.date) < timeInterval
        }
    }
    public func hasRecentTranscript(within timeInterval: TimeInterval) -> Bool {
        guard let lastTranscript = transcript.last else { return false }
        return Date().timeIntervalSince(lastTranscript.date) < timeInterval
    }
    public func oldestTranscriptTime(within timeInterval: TimeInterval) -> Date {
        let recentTranscript = recentTranscript(within: timeInterval)
        return recentTranscript.first?.date ?? Date.distantPast
    }
}
