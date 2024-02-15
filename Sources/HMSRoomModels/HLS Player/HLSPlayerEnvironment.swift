//
//  HLSPlayerEnvironment.swift
//  HMSRoomKitPreview
//
//  Created by Pawan Dixit on 2/15/24.
//

import SwiftUI

public struct HMSHLSPreferences {
    
    public var isControlsHidden = false
    public var resetHideTask: (() -> Void)?
    
    public init(isControlsHidden: Bool = false, resetHideTask: (() -> Void)? = nil) {
        self.isControlsHidden = isControlsHidden
        self.resetHideTask = resetHideTask
    }
    
    struct Key: EnvironmentKey {
        static let defaultValue: Binding<HMSHLSPreferences> = .constant(.init(isControlsHidden: false))
    }
}

public extension EnvironmentValues {
    
    var hlsPlayerPreferences: Binding<HMSHLSPreferences> {
        get { self[HMSHLSPreferences.Key.self] }
        set { self[HMSHLSPreferences.Key.self] = newValue }
    }
}
