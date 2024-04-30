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
import JWTDecode

public enum HMSRoomState {
    
    public enum RoomLeaveReason {
        case roomEnded(reasonString: String)
        case userLeft
        case removedFromRoom(reasonString: String)
    }
    
    case notJoined
    case inMeeting
    case leftMeeting(reason: RoomLeaveReason)
}

public enum HMSRoomRecordingState {
    case stopped
    case initializing
    case recording
    case failed
}

public enum HMSWhiteboardPermission {
    case read, write, admin
}

public class HMSRoomModel: ObservableObject {
    
    internal var joinCancellable: AnyCancellable?
    internal var previewCancellable: AnyCancellable?
    
    // Peer states
    @Published public var peerModels = [HMSPeerModel]()
    @Published public var peersSharingScreen = [HMSPeerModel]()
    
    // Local peer states
    @Published public var isMicMute: Bool = true
    @Published public var isCameraMute: Bool = true
    @Published public var userName: String
    @Published public private(set) var userId: String?
    @Published public var isPreviewJoined: Bool = false
    @Published public var isUserJoined: Bool = false
    @Published public var isUserSharingScreen: Bool = false
    @Published public var userCanEndRoom: Bool = false
    @Published public var userWhiteboardPermissions = Set<HMSWhiteboardPermission>()
    @Published public var userRole: HMSRole?
    
    public internal(set) var transcriptionStates: [HMSTranscriptionState]?
    public var transcript: String {
        transcriptArray.joined()
    }
    @Published internal var transcriptArray = [String]()
    internal var lastTranscript: HMSTranscript?
    
    // Meeting experience states
    @Published public var errors = [Error]()
    public var lastError: Error? {
        errors.last
    }
    @Published public var isReconnecting = false
    @Published public var isBeingStreamed: Bool = false
    @Published public var messages = [HMSMessage]()
    @Published public var serviceMessages = [HMSMessage]()
    
    // Room states
    @Published public var peerCount: Int? = nil
    @Published public var roomID: String?
    @Published public var name: String?
    @Published public var sessionID: String?
    @Published public var sessionStartedAt: Date?
    @Published public var recordingState: HMSRoomRecordingState = .stopped
    @Published public var speakers = [HMSPeerModel]()
    
    // Noise cancellation
    @Published internal var noiseCancellationPlugin: HMSNoiseCancellationPlugin?
    @Published public internal(set) var isNoiseCancellationAvailable: Bool = false
    @Published public internal(set) var isNoiseCancellationEnabled: Bool = false

    public var isLarge: Bool {
        room?.isLarge ?? false
    }

    // Room state
    @Published public var roomState: HMSRoomState = .notJoined {
        
        didSet {
#if !Preview
            if case .leftMeeting = roomState {
                sdk.remove(delegate: self)
                resetAllPeerAndRoomStates()
            }
#endif
        }
    }
    
    // Shared session metadata
    @Published internal var sessionStore: HMSSessionStore?
    @Published public var sharedStore: HMSSharedStorage<String, Any>?
    @Published internal var sharedSessionStore: HMSSharedSessionStore
    
    // in-memory data
    @Published public var inMemoryStore = [String: Any?]()
    public var inMemoryStaticStore = [String: Any?]()
    
    let roomCode: String?
    let providedToken: String?
    
    var authToken: String?
    let sdk: HMSSDK
    public var room: HMSRoom? = nil
    
    // Room states
    @Published public var hlsVariants = [HMSHLSVariant]()
    // Requests and notifications
    @Published public var roleChangeRequests = [HMSRoleChangeRequest]()
    @Published public var changeTrackStateRequests = [HMSChangeTrackStateRequest]()
    @Published public var removedFromRoomNotification: HMSRemovedFromRoomNotification?
    
    public var interactivityCenter: HMSInteractivityCenter {
        sdk.interactivityCenter
    }
    
    @Published public var isWhiteboardAvailable: Bool = false
    @Published public var whiteboard: HMSWhiteboard?
    
    public let options: HMSRoomOptions?
    public init(roomCode: String, options: HMSRoomOptions? = nil, builder: ((HMSSDK, HMSAudioTrackSettingsBuilder, HMSVideoTrackSettingsBuilder)->Void)? = nil) {
        self.roomCode = roomCode
        self.providedToken = nil

        self.options = options
        self.userName = options?.userName ?? ""
        self.userId = options?.userId
        
        var noiseCancellationPluginLocal: HMSNoiseCancellationPlugin?
        
        if let noiseCancellationParams = options?.noiseCancellation {
            noiseCancellationPluginLocal = .init(modelPath: noiseCancellationParams.model, initialState: noiseCancellationParams.initialState)
        }
                
        self.noiseCancellationPlugin = noiseCancellationPluginLocal
                
        self.sdk = HMSSDK.build() { sdk in
            if let groupName = options?.appGroupName {
                sdk.appGroup = groupName
            }
            sdk.trackSettings = HMSTrackSettings.build { videoSettingsBuilder, audioSettingsBuilder in
                
                if let noiseCancellationPluginLocal {
                    audioSettingsBuilder.noiseCancellationPlugin = noiseCancellationPluginLocal
                }
                
                builder?(sdk, audioSettingsBuilder, videoSettingsBuilder)
            }
        }
        
        sharedSessionStore = HMSSharedSessionStore()
        sharedSessionStore.roomModel = self
        
        #if !Preview
        sdk.logger = self
        #endif
    }
    
    public init(token: String, options: HMSRoomOptions? = nil, builder: ((HMSSDK, HMSAudioTrackSettingsBuilder, HMSVideoTrackSettingsBuilder)->Void)? = nil) {
        self.roomCode = nil
        self.providedToken = token
        
        self.options = options
        self.userName = options?.userName ?? ""
        
        do {
            let jwt = try decode(jwt: token)
            let userId = jwt.claim(name: "user_id").string
            self.userId = userId
        }
        catch {
            self.userId = nil
        }
        
        var noiseCancellationPluginLocal: HMSNoiseCancellationPlugin?
        
        if let noiseCancellationParams = options?.noiseCancellation {
            noiseCancellationPluginLocal = .init(modelPath: noiseCancellationParams.model, initialState: noiseCancellationParams.initialState)
        }
                
        self.noiseCancellationPlugin = noiseCancellationPluginLocal
                
        self.sdk = HMSSDK.build() { sdk in
            if let groupName = options?.appGroupName {
                sdk.appGroup = groupName
            }
            sdk.trackSettings = HMSTrackSettings.build { videoSettingsBuilder, audioSettingsBuilder in
                
                if let noiseCancellationPluginLocal {
                    audioSettingsBuilder.noiseCancellationPlugin = noiseCancellationPluginLocal
                }
                
                builder?(sdk, audioSettingsBuilder, videoSettingsBuilder)
            }
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
        
        noiseCancellationPlugin = nil
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
    
    
    
#else
    public init(){
        sharedSessionStore = HMSSharedSessionStore()
        roomCode = "nil-some-code"
        providedToken = nil
        sdk = .build()
        options = nil
        userName = ""
    }
#endif
    @Published public var roles = [HMSRole]()
}

#if !Preview
extension HMSRoomModel: HMSLogger {
    public func log(_ message: String, _ level: HMSAnalyticsSDK.HMSLogLevel) {
        print(message)
    }
}
#endif
