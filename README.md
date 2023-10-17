# 🎉 100ms Meeting Room Models 🚀
Introducing meeting room models that simplify SwiftUI based application development using 100ms SDK
  
# Pre-requisites
- Xcode 14 or higher
- iOS 15 or higher

# Integration

You can integrate RoomModels SDK into your project using Swift Package Manager (SPM). Follow these steps:

1. Open your Xcode project.
2. Navigate to `File` > `Add Package Dependency`.
3. In the dialog that appears, enter the following URL as the package source: https://github.com/100mslive/100ms-roomkit-models-ios
4. Click `Next` and follow the prompts to add the package to your project.

# RoomModels Basics

#### Import SDK
You import the RoomModels SDK with following import statement

```swift
import HMSRoomModels
```

#### Create a Room Model

You can create a reactive model of the room with either a [room-code](https://www.100ms.live/docs/get-started/v2/get-started/prebuilt/room-codes/overview) or an [auth-token](https://www.100ms.live/docs/get-started/v2/get-started/security-and-tokens#auth-token-for-client-sdks) like below:

```swift
// Initialize with room-code
let roomModel = HMSRoomModel(roomCode: /*pass room code as string here*/)
```

```swift
// Initialize with auth-token
let roomModel = HMSRoomModel(token: /*pass role's auth token as string here*/)
```

# How to Join/Leave a Room

You call joinSession and leaveSession on RoomModel instance to join and leave the room.

Example: Simple Meeting View with join and leave.

```swift
struct MeetingView: View {
    
    @ObservedObject var roomModel = HMSRoomModel(roomCode: "qdr-mik-seb")
    
    var body: some View {
        
        Group {
            switch roomModel.roomState {
            case .none, .leave:
                Button(action: {
                    Task {
                        try await roomModel.joinSession(userName: "iOS User")
                    }
                }, label: {
                    Text("Join")
                })
            case .meeting:
                VStack {
                    Button(action: {
                        Task {
                            try await roomModel.leaveSession()
                        }
                    }, label: {
                        Text("Leave")
                    })
                }
            }
        }
    }
}
```

# How to display live streaming video

You can use HMSVideoTrackView and pass a peer model to render it's video track.

Example: Simple Meeting View to render each peer's video in a list view.

```swift
struct MeetingView: View {
    
    @ObservedObject var roomModel = HMSRoomModel(roomCode: "qdr-mik-seb")
    
    var body: some View {
        
        Group {
            switch roomModel.roomState {
            case .none, .leave:
                Button(action: {
                    Task {
                        try await roomModel.joinSession(userName: "iOS User")
                    }
                }, label: {
                    Text("Join")
                })
            case .meeting:
                VStack {
                    List {
                        ForEach(roomModel.peerModels) { peerModel in
                            
                            VStack {
                                Text(peerModel.name)
                                HMSVideoTrackView(peer: peerModel)
                                    .frame(height: 200)
                            }
                        }
                    }
                    
                    Button(action: {
                        Task {
                            try await roomModel.leaveSession()
                        }
                    }, label: {
                        Text("Leave")
                    })
                }
            }
        }
    }
}
```

# How to Mute/Unmute Audio and Video

You can call **toggleMic** or **toggleCamera** method on RoomModel instance to toggle audio and video. You can also check whether the mic and camera is on by checking **isMicMute** and **isCameraMute** property on RoomModel instance.

Example: Simple Meeting View to show mic and camera toggle controls.

```swift
struct MeetingView: View {
    
    @ObservedObject var roomModel = HMSRoomModel(roomCode: "qdr-mik-seb")
    
    var body: some View {
        
        Group {
            switch roomModel.roomState {
            case .none, .leave:
                ...
            case .meeting:
                VStack {
                    ...
                    
                    HStack {
                        Image(systemName: roomModel.isMicMute ? "mic.slash" : "mic")
                            .onTapGesture {
                                roomModel.toggleMic()
                            }
                        
                        Image(systemName: roomModel.isCameraMute ? "video.slash" : "video")
                            .onTapGesture {
                                roomModel.toggleCamera()
                            }
                        
                        Image(systemName: "phone.down.fill")
                            .onTapGesture {
                                Task {
                                    try await roomModel.leaveSession()
                                }
                            }
                    }
                }
            }
        }
    }
}
```

# How to Perform Actions

You can also perform actions on RoomModel, PeerModels and TrackModels.

#### Preview the Room

Preview screen is a frequently used UX element which allows users to check if their input devices are working properly and set the initial state (mute/unmute) of their audio and video tracks before joining.

You call preview method on the Room model instance to preview the room. You can optionally pass the name of the participant in the preview method.

```swift
roomModel.preview(userName: /*pass participant's name as string here*/)
```

#### Join the Room

To join and interact with others in audio or video call, the user needs to join a room.

You call join method on Room Model instance to join the room. You can optionally pass the name of the participant in the join method.

```swift
roomModel.join(userName: /*pass participant's name as string here*/)
```

# Actions on Local User

#### Toggle Mic

```swift
roomModel.toggleMic()
```

#### Toggle Camera

```swift
roomModel.toggleCamera()
```

#### Leave session

```swift
try await roomModel.leaveSession()
```

#### End Session for all

```swift
try await roomModel.endSession()
```

#### Switch Camera (Front/Back)

```swift
try await roomModel.switchCamera()
```

#### Change local participant's name

```swift
try await roomModel.changeUserName(/* new name as string */)
```

# Actions on remote participants

#### Remove a peer from meeting

```swift
roomModel.remove(peer: /* HMSPeerModel instance */)
```

Example: Remove a random remote particiapnt from the call.

```swift
guard let randomRemoteParticiapnt = roomModel.remotePeerModels.randomElement() else {return}
roomModel.remove(peer: randomRemoteParticiapnt)
```

#### Send chat message to a remote participant

```swift
try await roomModel.send(message: /* text message as string */, to recipient: /* instance of HMSRecipient */, type: /* optional type of message; type is "chat" by default*/)
```

Example: Send a text message to everyone.

```swift
try await roomModel.send("How is it going?", to: .everyone)
```

#### Change role of a participant

```swift
try await roomModel.changeRole(of: /* instance of HMSPeerModel */, to: /* role's name as string */, force: /* optional boolean to denote if role should change immediately or after the participant's approval */)
```

Example: Send a text message to everyone.

```swift
guard let student = roomModel.remotePeerModels.filter(withRoles: ["student"]).first else {return}
try await roomModel.changeRole(of: student, to: "Stage")
```

#### Raise/Lower hand of a participant

```swift

// Raise hand of local participant
try await roomModel.raiseHand()

// Lower hand of local participant
try await roomModel.lowerHand()

// Lower hand of a participant
try await roomModel.lowerHand(of: /* instance of HMSPeerModel */)
```


# Actions related to Conferecne/Live-streaming Room


#### Start/Stop streaming the Room

```swift
try await roomModel.startStreaming()
```
```swift
try await roomModel.stopStreaming()
```


#### Start/Stop recording the Room

```swift
try await roomModel.startRecording()
```

```swift
try await roomModel.stopRecording()
```
