//
//  HMSObservablePeerListIterator.swift
//  HMSRoomKitDevelopmentProject
//
//  Created by Dmitry Fedoseyev on 22.09.2023.
//

import Foundation
import HMSSDK

@MainActor
public final class HMSPeerListModel: ObservableObject {
    
    @Published public private(set) var peers: [HMSPeerModel]
    @Published public private(set) var hasMorePeers: Bool
    @Published public private(set) var isLoadingPeers: Bool
    @Published public private(set) var totalPeerCount: Int

    public var options: HMSPeerListIteratorOptions {
        iterator.options
    }
    
    private var currentIDs = Set<String>()
    private var iterator: HMSPeerListIterator
    private var modelBuilder: ((HMSPeer) -> HMSPeerModel)
    
    init(iterator: HMSPeerListIterator, modelBuilder: @escaping ((HMSPeer) -> HMSPeerModel)) {
        self.peers = []
        self.hasMorePeers = true
        self.isLoadingPeers = false
        self.totalPeerCount = 0
        self.modelBuilder = modelBuilder
        self.iterator = iterator
    }
    
    private func append(_ newPeers: [HMSPeer]) {
        let uniquePeers = newPeers.filter { !currentIDs.contains($0.peerID) }
        let newModels = uniquePeers.map { modelBuilder($0) }
        peers.append(contentsOf: newModels)
        
        let newIDs = uniquePeers.map { $0.peerID }
        currentIDs.formUnion(newIDs)
    }
    
    public func loadNextSetOfPeers() async throws {
        isLoadingPeers = true
        return try await withCheckedThrowingContinuation { continuation in
            iterator.next() { [weak self] newPeers, error in
                guard let self = self else { return }
                if let error = error {
                    self.isLoadingPeers = false
                    continuation.resume(throwing: error)
                } else {
                    self.append(newPeers ?? [])
                    self.hasMorePeers = iterator.hasNext
                    self.totalPeerCount = iterator.totalCount
                    self.isLoadingPeers = false
                    continuation.resume()
                }
            }
        }
    }
}
