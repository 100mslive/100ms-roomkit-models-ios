//
//  HMSRoomModelPreviewExtension.swift
//  HMSSwiftUIPreviewDummy
//
//  Created by Pawan Dixit on 27/06/2023.
//  Copyright © 2023 100ms. All rights reserved.
//

import Foundation
import HMSSDK

#if Preview
extension HMSRoomModel {

    public var previewAudioTrack: HMSTrackModel? { HMSTrackModel() }
    public var previewVideoTrack: HMSTrackModel? { HMSTrackModel() }
    public var localVideoTrackModel: HMSTrackModel? { HMSTrackModel() }
    public var localAudioTrackModel: HMSTrackModel? { HMSTrackModel() }
    
    public enum AdditionalPeers {
        case screen
        case prominent
    }
    
    public static let localPeer = HMSPeerModel(name: "Local Peer", isLocal: true)
    private static let prominentPeers = [HMSPeerModel(name: "Prominent Peer \(1)"), HMSPeerModel(name: "Prominent Peer \(2)"), HMSPeerModel(name: "Prominent Peer \(3)"), HMSPeerModel(name: "Prominent Peer \(4)")]
    public static func prominentPeers(_ count: Int) -> [HMSPeerModel] {
        Array(prominentPeers.prefix(count))
    }
    public static var screenSharingPeers = [HMSPeerModel]()
    public static func dummyRoom(_ remotePeerCount: Int, _ additionalPeers: [AdditionalPeers] = []) -> HMSRoomModel {
        
        let room = HMSRoomModel()
        room.recordingState = .recording
        room.isBeingStreamed = true
        room.isUserJoined = true
        room.userCanEndRoom = true
        
        room.sharedStore = HMSSharedStorage(setHandler: { _, _ in
        })
        room.pinnedMessages = [.init(text: "Pawan: hello there", id: "1", pinnedBy: "local user"), .init(text: "Dmitry: what's up", id: "2", pinnedBy: "user 1"), .init(text: "Nihal: this message is supposed to be very long so that we can see how a multiline pinned message will look like in the UI. this message is supposed https://stackoverflow.com/questions/57744392/how-to-make-hyperlinks-in-swiftui to be very long so that we can see how a multiline pinned message will look like in the UI.", id: "3", pinnedBy: "remote user")]
        
        room.messages = [HMSMessage(message: "wph"), HMSMessage(message: "hey"), HMSMessage(message: "hey"), HMSMessage(message: "hey"), HMSMessage(message: "hey"), HMSMessage(message: "hey"), HMSMessage(message: "hey"), HMSMessage(message: "hey"), HMSMessage(message: "hey"), HMSMessage(message: "hey"), HMSMessage(message: "hey"), HMSMessage(message: "hey")]
        
        room.userName = "Pawan's iOS"
        room.roles = []
        
        var peers = [localPeer]
        if remotePeerCount > 0 {
            peers.append(contentsOf: (0..<remotePeerCount).map { i in HMSPeerModel(name: "Remote Peer \(i)") })
        }
        peers.forEach {
            $0.downlinkQuality = Int.random(in: 0..<5)
        }
        
        if additionalPeers.contains(.screen) {
            let count = additionalPeers.filter{$0 == .screen}.count
            
            for i in 0..<count {
                let peer = HMSPeerModel(name: "ScreenSharing Peer \(i)")
                room.peersSharingScreen.append(peer)
                peers.append(peer)
                screenSharingPeers.append(peer)
            }
        }
        if additionalPeers.contains(.prominent) {
            let count = additionalPeers.filter{$0 == .prominent}.count
            
            let prominentPeers = prominentPeers.prefix(count)
            peers.append(contentsOf: prominentPeers)
        }
        room.isBeingStreamed = true
        room.peerModels = peers
        
        room.peerCount = peers.count
        
        return room
    }
}
#endif
