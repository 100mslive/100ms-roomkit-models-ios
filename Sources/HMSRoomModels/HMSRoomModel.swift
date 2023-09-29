//
//  HMSRoom.swift
//  HMSUIKit
//
//  Created by Pawan Dixit on 29/05/2023.
//

import SwiftUI
import Combine
import HMSSDK
import HMSAnalyticsSDK

public enum HMSRoomState {
    
    public enum LeaveReason {
        case roomEnded
        case userLeft
        case userKickedOut
    }
    
    case none
    case meeting
    case leave(reason: LeaveReason)
}

public enum HMSRoomRecordingState {
    case stopped
    case initializing
    case recording
    case failed
}

public class HMSRoomModel: ObservableObject {
    
    internal var joinCancellable: AnyCancellable?
    internal var previewCancellable: AnyCancellable?
    
    deinit {
        print("pawan: deinit")
    }
    
    // Peer states
    @Published public var peerModels = [HMSPeerModel]()
    @Published public var peersSharingScreen = [HMSPeerModel]()
    
    // Local peer states
    @Published public var isMicMute: Bool = true
    @Published public var isCameraMute: Bool = true
    @Published public var userName: String = ""
    @Published public var isPreviewJoined: Bool = false
    @Published public var isUserJoined: Bool = false
    @Published public var isUserSharingScreen: Bool = false
    @Published public var userCanEndRoom: Bool = false
    
#if !Preview
    @Published public var userRole: HMSRole?
#endif
    
    // Meeting experience states
    @Published public var errors = [Error]()
    public var lastError: Error? {
        errors.last
    }
    @Published public var isReconnecting = false
    @Published public var isBeingStreamed: Bool = false
#if !Preview
    @Published public var messages = [HMSMessage]()
    @Published public var serviceMessages = [HMSMessage]()
#else
    @Published public var messages = [HMSMessageModel]()
#endif
    
    // Room states
    @Published public var peerCount: Int? = nil
    @Published public var roomID: String?
    @Published public var name: String?
    @Published public var sessionID: String?
    @Published public var sessionStartedAt: Date?
    @Published public var recordingState: HMSRoomRecordingState = .stopped
    @Published public var speakers = [HMSPeerModel]()

    public var isLarge: Bool {
        room?.isLarge ?? false
    }

    // Room state
    @Published public var roomState: HMSRoomState = .none {
        
        didSet {
#if !Preview
            if case .leave = roomState {
                sdk.remove(delegate: self)
                resetAllPeerAndRoomStates()
            }
#endif
        }
    }
    
    // Shared session metadata
    @Published internal var sessionStore: HMSSessionStore?
    @Published public var sharedStore: HMSSharedStorage<String, Any>?
    @Published public var sharedSessionStore: HMSSharedSessionStore
    
    // in-memory data
    @Published public var inMemoryStore = [String: Any?]()
    public var inMemoryStaticStore = [String: Any?]()
    
    let roomCode: String?
    let providedToken: String?
    
    var authToken: String?
    let sdk: HMSSDK
    var room: HMSRoom? = nil
    
    // Room states
    @Published public var hlsVariants = [HMSHLSVariant]()
    // Requests and notifications
    @Published public var roleChangeRequests = [HMSRoleChangeRequest]()
    @Published public var changeTrackStateRequests = [HMSChangeTrackStateRequest]()
    @Published public var removedFromRoomNotification: HMSRemovedFromRoomNotification?
    
    public let options: HMSRoomOptions?
    public init(roomCode: String, options: HMSRoomOptions? = nil, builder: ((HMSSDK)->Void)? = nil) {
        self.roomCode = roomCode
        self.providedToken = nil
        
        self.options = options
        
        self.sdk = HMSSDK.build() { sdk in
            if let groupName = options?.appGroupName {
                sdk.appGroup = groupName
            }
            builder?(sdk)
        }
        
        sharedSessionStore = HMSSharedSessionStore()
        sharedSessionStore.roomModel = self
        
        #if !Preview
        sdk.logger = self
        #endif
    }
    
    public init(token: String, options: HMSRoomOptions? = nil, builder: ((HMSSDK)->Void)? = nil) {
        self.roomCode = nil
        self.providedToken = token
        
        self.options = options
        
        self.sdk = HMSSDK.build() { sdk in
            if let groupName = options?.appGroupName {
                sdk.appGroup = groupName
            }
            builder?(sdk)
        }
        
        sharedSessionStore = HMSSharedSessionStore()
        sharedSessionStore.roomModel = self
        
        #if !Preview
        sdk.logger = self
        #endif
    }
    
#if !Preview
    private func resetAllPeerAndRoomStates() {
        
        peerModels.removeAll()
        peersSharingScreen.removeAll()
        
        isMicMute = true
        isCameraMute = true
        isUserJoined = false
        isPreviewJoined = false
        
        userRole = nil
        
        errors.removeAll()
        isReconnecting = false
        isBeingStreamed = false
        messages.removeAll()
        
        peerCount = nil
        roomID = nil
        name = nil
        sessionID = nil
        sessionStartedAt = nil
        recordingState = .stopped
        speakers.removeAll()
        
        authToken = nil
        
        room = nil
        
        previewVideoTrack = nil
        previewAudioTrack = nil
        
        hlsVariants = []
        roles.removeAll()
        
        roleChangeRequests.removeAll()
        changeTrackStateRequests.removeAll()
        removedFromRoomNotification = nil
        
        sessionStore = nil
        sharedStore = nil
        sharedSessionStore.cleanup()
        
        inMemoryStore.removeAll()
    }
    
    // Preview states
    @Published public var previewVideoTrack: HMSTrackModel? {
        didSet {
            Task { @MainActor in
                updateLocalMuteState()
            }
        }
    }
    @Published public var previewAudioTrack: HMSTrackModel? {
        didSet {
            Task { @MainActor in
                updateLocalMuteState()
            }
        }
    }
    
    @Published public var roles = [HMSRole]()
    
#else
    @Published public var roles = [PreviewRoleModel]()
    public init(){
        sharedSessionStore = HMSSharedSessionStore()
        roomCode = nil
        providedToken = nil
        sdk = .build()
        options = nil
    }
#endif
}

#if !Preview
extension HMSRoomModel: HMSLogger {
    public func log(_ message: String, _ level: HMSAnalyticsSDK.HMSLogLevel) {
        print(message)
    }
}
#endif
