//
//  HMSNoiseCancellation.swift
//
//
//  Created by Pawan Dixit on 2/26/24.
//

import Foundation
import HMSSDK

public struct HMSVirtualBackground {
    
    public enum InitialState {
        case enabled, disabled
    }
    
    let operatingMode: HMSVirtualBackgroundPlugin.OperatingMode
    let initialState: InitialState
    
    public init(with operatingMode: HMSVirtualBackgroundPlugin.OperatingMode, initialState: InitialState) {
        self.operatingMode = operatingMode
        self.initialState = initialState
    }
}
