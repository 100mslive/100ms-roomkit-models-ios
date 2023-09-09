//
//  File.swift
//  
//
//  Created by Pawan Dixit on 09/09/2023.
//

import Foundation

public class HMSRoomOptions: ObservableObject {
    
    public let appGroupName: String?
    public let screenShareBroadcastExtensionBundleId: String?
    
    public init(appGroupName: String? = nil, screenShareBroadcastExtensionBundleId: String? = nil) {
        self.appGroupName = appGroupName
        self.screenShareBroadcastExtensionBundleId = screenShareBroadcastExtensionBundleId
    }
}
