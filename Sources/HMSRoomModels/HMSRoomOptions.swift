//
//  File.swift
//  
//
//  Created by Pawan Dixit on 09/09/2023.
//

import Foundation

public class HMSRoomOptions: ObservableObject {
    
    public let userName: String?
    public let userId: String?
    
    public let appGroupName: String?
    public let screenShareBroadcastExtensionBundleId: String?
    
    public init(userName: String? = nil, userId: String? = nil, appGroupName: String? = nil, screenShareBroadcastExtensionBundleId: String? = nil) {
        self.appGroupName = appGroupName
        self.screenShareBroadcastExtensionBundleId = screenShareBroadcastExtensionBundleId
        self.userName = userName
        self.userId = userId
    }
}
