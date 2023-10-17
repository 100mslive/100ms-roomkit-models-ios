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

You call **joinSession** and **leaveSession** on RoomModel instance to join and leave the room.

Example: Simple Meeting View with join and leave.

```swift
struct MeetingView: View {
    
    @ObservedObject var roomModel = HMSRoomModel(roomCode: "qdr-mik-seb")
    
    var body: some View {
        
        Group {
            switch roomModel.roomState {
            case .none, .leave:
                // Button to join the room
                Button(action: {
                    Task {
                        try await roomModel.joinSession(userName: "iOS User")
                    }
                }, label: {
                    Text("Join")
                })
            case .meeting:
                VStack {
                    // Button to leave the room
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

You can use **HMSVideoTrackView** and pass a **peer model** instance to show/render its video track.

Example: Simple Meeting View to render each peer's video in a list view.

```swift
struct MeetingView: View {
    
    @ObservedObject var roomModel = HMSRoomModel(roomCode: "qdr-mik-seb")
    
    var body: some View {
        
        Group {
            switch roomModel.roomState {
            case .none, .leave:
                // Button to join the room
                ...
            case .meeting:
                VStack {
                    // Render video of each peer in the call
                    List {
                        ForEach(roomModel.peerModels) { peerModel in
                            
                            VStack {
                                Text(peerModel.name)
                                HMSVideoTrackView(peer: peerModel)
                                    .frame(height: 200)
                            }
                        }
                    }

                    // Button to leave the room
                    ...
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
                // Button to join the room
                ...
            case .meeting:
                VStack {
                    // Render video of each peer in the call
                    ...
                    
                    HStack {

                        // Toggle local user's mic
                        Image(systemName: roomModel.isMicMute ? "mic.slash" : "mic")
                            .onTapGesture {
                                roomModel.toggleMic()
                            }

                        // Toggle local user's camera
                        Image(systemName: roomModel.isCameraMute ? "video.slash" : "video")
                            .onTapGesture {
                                roomModel.toggleCamera()
                            }

                        // Button to leave the room
                        ...
                    }
                }
            }
        }
    }
}
```

# How to send message to another participant

You use **send(message: , to:)** method on RoomModel instance to send a message to another participant.

```swift
try await roomModel.send(message: /* text message as string */, to recipient: /* instance of HMSRecipient */, type: /* optional type of message; type is "chat" by default*/)
```

Example: Send a text message **to everyone**.

```swift
try await roomModel.send("How is it going?", to: .everyone)
```

Example: Send a text message **to a random remote participant**.

```swift
guard let randomRemoteParticiapnt = roomModel.remotePeerModels.randomElement() else {return}
try await roomModel.send(message: "How is it going?", to: .peer(randomRemoteParticiapnt))
```

Example: Send a text message **to a all participant with student role**.

```swift
guard let studentRole = (roomModel.roles.first{$0.name == "student"}) else { return }
try await roomModel.send(message: "How is it going?", to: .role(studentRole))
```

# How to show a Participant's Screen

You use **HMSScreenTrackView** and pass a peer model to show/render its screen track. You can check which participants are sharing their screens using **peersSharingScreen** property of RoomModel instance.

```swift
...

// Render video of each peer in the call
    List {

        // If a participant is sharing their screen, show their screen at the top of the list
        if roomModel.peersSharingScreen.count > 0 {
            TabView {
                ForEach(roomModel.peersSharingScreen) { screenSharingPeer in
                    HMSScreenTrackView(peer: screenSharingPeer)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 200)
        }

        // Render video of each peer in the call
        ForEach(roomModel.peerModels) { peerModel in
            VStack {
                Text(peerModel.name)
                HMSVideoTrackView(peer: peerModel)
                    .frame(height: 200)
            }
        }
    }

...
```

# How to share screen of local user

You need to follow following steps to be able to share screen from iOS app:

1. Make a new **Broadcast Upload Extension** target from Xcode. This target will be embedded into your application. Xcode automatically sets everything up if you use Xcode template named **Broadcast Upload Extension** to create the target.
2. Add **App Group** capability in your **main app** target as well as in this new **Broadcast Upload Extension** target. Use the same App Group ID in both the targets. Let's assume your app group id is "group.live.100ms.videoapp.roomkit".
3. Add **HMSBroadcastExtensionSDK** to your **main app** target from Swift Package Manager. You can use Swift Package Manager (use https://github.com/100mslive/100ms-ios-broadcast-sdk.git as the package source) to add this SDK to your app. Then add **HMSBroadcastExtensionSDK** to your iOS **Broadcast Upload Extension** target using plus button in target's framework and libraries section.
4. Xcode creates a **SampleHandler.swift** file in a new folder for your **Broadcast Upload Extension** target. Modify this **SampleHandler.swift** file to contain the following code (delete all the code in **SampleHandler.swift** file and paste the following code):

```swift
import HMSBroadcastExtensionSDK

class SampleHandler: HMSBroadcastSampleHandler {
    
    override var appGroupId: String {
        "group.live.100ms.videoapp.roomkit"
    }
}
```

Where "group.live.100ms.videoapp.roomkit" is the app group ID of your app group that created in step 2. Make sure to replace it with your App Group ID string.

5. With the above steps completed, let your RoomModel instance know about your App Group ID and your extension's bundle identifier like below:

```swift
@ObservedObject var roomModel = HMSRoomModel(roomCode: "qdw-mil-sev", options: .init(appGroupName: "group.live.100ms.videoapp.roomkit", screenShareBroadcastExtensionBundleId: "live.100ms.videoapp.roomkit.Screenshare"))
```

Where "live.100ms.videoapp.roomkit.Screenshare" is the bundle id of your **Broadcast Upload Extension** target.

6. At this point you are ready to share screen of local iOS user. You can use the following code to make a button to start screen sharing from inside your app UI:

```swift
if roomModel.userCanShareScreen {
    HMSShareScreenButton {
        Image(systemName: "rectangle.inset.filled.and.person.filled")
    }
    .environmentObject(roomModel)
}
```

Note that definition of HMSShareScreenButton is following that you can use in your app:

```swift
import SwiftUI
import ReplayKit
import Combine
import HMSRoomModels

extension RPSystemBroadcastPickerView: ObservableObject {}
public struct HMSShareScreenButton<Content>: View where Content : View {
    
    @EnvironmentObject var room: HMSRoomModel
    
    @StateObject var broadcastPickerView = {
        let picker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        picker.showsMicrophoneButton = false
        return picker
    }()
    
    let onTap:(()->Void)?
    @ViewBuilder let content: () -> Content
    public init(onTap:(()->Void)? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.onTap = onTap
    }
    
    public var body: some View {
        content()
        .background(Color.black.opacity(0.0001))
        .onTapGesture {
            for subview in broadcastPickerView.subviews {
                if let button = subview as? UIButton {
                    button.sendActions(for: UIControl.Event.allTouchEvents)
                }
            }
            onTap?()
        }
        .onAppear() {
            broadcastPickerView.preferredExtension = room.options?.screenShareBroadcastExtensionBundleId
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
