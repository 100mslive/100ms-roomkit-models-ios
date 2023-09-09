//
//  File.swift
//  
//
//  Created by Pawan Dixit on 09/09/2023.
//

import Foundation

public class HMSRoomOptions: ObservableObject {
    
    var appGroupName: String?
    var preferredExtensionName: String?
    
    public init(appGroupName: String? = nil, preferredExtensionName: String? = nil) {
        self.appGroupName = appGroupName
        self.preferredExtensionName = preferredExtensionName
    }
}
