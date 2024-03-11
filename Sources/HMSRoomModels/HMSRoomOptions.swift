//
//  HMSRoomOptions.swift
//  
//
//  Created by Pawan Dixit on 09/09/2023.
//

import Foundation
import HMSSDK

public class HMSRoomOptions: ObservableObject {
    
    public let userName: String?
    public let userId: String?
    
    public let appGroupName: String?
    public let screenShareBroadcastExtensionBundleId: String?
    
    public let noiseCancellation: HMSNoiseCancellation?
    
    public init(userName: String? = nil, userId: String? = nil, appGroupName: String? = nil, screenShareBroadcastExtensionBundleId: String? = nil, noiseCancellation: HMSNoiseCancellation? = nil) {
        self.appGroupName = appGroupName
        self.screenShareBroadcastExtensionBundleId = screenShareBroadcastExtensionBundleId
        self.userName = userName
        self.userId = userId
        self.noiseCancellation = noiseCancellation
    }
}
