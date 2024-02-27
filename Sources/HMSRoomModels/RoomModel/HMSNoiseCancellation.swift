//
//  File.swift
//  
//
//  Created by Pawan Dixit on 2/26/24.
//

import Foundation
import HMSSDK

public struct HMSNoiseCancellation {
    
    let model: String
    let initialState: HMSNoiseCancellationInitialState
    
    public init(with model: String, initialState: HMSNoiseCancellationInitialState) {
        self.model = model
        self.initialState = initialState
    }
}
