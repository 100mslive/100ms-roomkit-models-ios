//
//  HMSObservablePeerListIterator.swift
//  HMSRoomKitDevelopmentProject
//
//  Created by Dmitry Fedoseyev on 22.09.2023.
//

import Foundation
import HMSSDK

@MainActor
public final class HMSPeerListLoader: ObservableObject {
    @Published public private(set) var peers: [HMSPeerModel]
    @Published public private(set) var hasNext: Bool
    @Published public private(set) var isLoading: Bool
    @Published public private(set) var totalCount: Int

    public var options: HMSPeerListIteratorOptions {
        iterator.options
    }
    
    private var currentIDs = Set<String>()
    private var iterator: HMSPeerListIterator
    private var modelBuilder: ((HMSPeer) -> HMSPeerModel)
    
    init(iterator: HMSPeerListIterator, modelBuilder: @escaping ((HMSPeer) -> HMSPeerModel)) {
        self.peers = []
        self.hasNext = true
        self.isLoading = false
        self.totalCount = 0
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
    
    public func loadNext() async throws {
        isLoading = true
        return try await withCheckedThrowingContinuation { continuation in
            iterator.next() { [weak self] newPeers, error in
                guard let self = self else { return }
                if let error = error {
                    self.isLoading = false
                    continuation.resume(throwing: error)
                } else {
                    self.append(newPeers ?? [])
                    self.hasNext = iterator.hasNext
                    self.totalCount = iterator.totalCount
                    self.isLoading = false
                    continuation.resume()
                }
            }
        }
    }
}
