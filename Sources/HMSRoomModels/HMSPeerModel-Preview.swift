//
//  HMSPeerModelExtension.swift
//  HMSRoomKit
//
//  Created by Pawan Dixit on 27/06/2023.
//  Copyright © 2023 100ms. All rights reserved.
//

import SwiftUI

#if Preview
extension HMSPeerModel {
    public var audioTrackModels: [HMSTrackModel] { [HMSTrackModel()] }
    public var regularVideoTrackModels: [HMSTrackModel] { [HMSTrackModel()] }
    public var screenTrackModels: [HMSTrackModel] { [HMSTrackModel()] }
    public var isSharingScreen: Bool { false }
}
#endif
