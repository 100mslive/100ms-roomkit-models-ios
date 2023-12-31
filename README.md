# 🎉 100ms Meeting Room Models 🚀
Introducing meeting room models that simplify SwiftUI based application development using 100ms SDK

Checkout the complete API documentation [here](https://www.100ms.live/docs/api-reference/ios/HMSRoomModelsSDK/documentation/hmsroommodels/hmsroommodel).
  
# Pre-requisites
- Xcode 14 or higher
- iOS 15 or higher

# Integration

You can integrate RoomModels SDK into your project using Swift Package Manager (SPM). Follow these steps:

1. Open your Xcode project.
2. Navigate to `File` > `Add Package Dependency`.
3. In the dialog that appears, enter the following URL as the package source: https://github.com/100mslive/100ms-roomkit-models-ios
4. Click `Next` and follow the prompts to add the package to your project.

# RoomModels SDK Basics

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
        
        switch roomModel.roomState {
        case .notJoined, .leftMeeting:
            // Button to join the room
            Button {
                Task {
                    try await roomModel.joinSession(userName: "iOS User")
                }
            } label: {
                Text("Join")
            }
        case .inMeeting:
            VStack {
                // Button to leave the room
                Button {
                    Task {
                        try await roomModel.leaveSession()
                    }
                } label: {
                    Text("Leave")
                }
            }
        }
    }
}
```

### How to end the Room

Call **endSession** method on HMSRoomModel instance.

```swift
try await roomModel.endSession(withReason reason: /* an optional string describing the reason for ending the session for everyone*/, shouldAllowReJoin: /* an optional bool whether anyone should be allowed to join the room after it has been ended*/)
```

Example: End a class room locking it so that no-one can join/start the room again.

```swift
try await roomModel.endSession(withReason: "Class has been over.", shouldAllowReJoin: false)
```

### How to know when the Room has been ended

You check the **roomState** property on HMSRoomModel instance and see if it's set to **leftMeeting(reason: RoomLeaveReason)** enum.

```swift
struct MeetingView: View {
    
    @ObservedObject var roomModel = HMSRoomModel(roomCode: "qdr-mik-seb")
    
    var body: some View {
        
        switch roomModel.roomState {
        case .notJoined:
            // Button to join the room
            ...
        case .inMeeting:
            VStack {
                // Button to leave the room
                ...
            }
        case .leftMeeting(reason: let reason):
            if reason == .roomEnded {
                // show room ended view here
            }
        }
    }
}
```

where leave reasons can be following:
```swift
public enum RoomLeaveReason {
    case roomEnded(reasonString: String)
    case userLeft
    case removedFromRoom(reasonString: String)
}
```

### How to remove a Participant from the Room

Can't let just let anyone remove others from the room. First you need to create a role with the permissions to **removeOthers** from the room. Once this permission is checked in the dashboard for current user's role, you can call **remove(peer, withReason:)** method on Room Model instance to remove a remote participant.

```swift
try await roomModel.remove(peer: /* peer model instance*/, withReason reason: /* an optional string describing the reason for ending the session for everyone*/)
```

Example: Kick out a student out of the class room.

```swift
guard let studentPeerModel = (roomModel.peerModels.first{$0.name == "Pawan"}) else { return }
try await roomModel.remove(peer: studentPeerModel, withReason: "Expelled from class.")
```

# How to display live streaming video

You can use **HMSVideoTrackView** and pass a **peer model** instance to show/render its video track.

Example: Simple Meeting View to render each peer's video in a list.

```swift
struct MeetingView: View {
    
    @ObservedObject var roomModel = HMSRoomModel(roomCode: "qdr-mik-seb")
    
    var body: some View {
        
        switch roomModel.roomState {
        case .notJoined, .leftMeeting:
            // Button to join the room
            ...
        case .inMeeting:
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
```

### How to show/render a Participant's Screen Track

You use **HMSScreenTrackView** and pass a peer model to show/render its screen track. You can check which participants are sharing their screens using **peersSharingScreen** property of RoomModel instance.

Example: If a participant is sharing their screen, show their screen at the top of the peer video list.

```swift
...

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

# How to Mute/Unmute Audio and Video

You can call **toggleMic** or **toggleCamera** method on RoomModel instance to toggle audio and video. You can also check whether the mic and camera is on by checking **isMicMute** and **isCameraMute** property on RoomModel instance.

Example: Simple Meeting View to show mic and camera toggle controls.

```swift
struct MeetingView: View {
    
    @ObservedObject var roomModel = HMSRoomModel(roomCode: "qdr-mik-seb")
    
    var body: some View {
        
        switch roomModel.roomState {
        case .notJoined, .leftMeeting:
            // Button to join the room
            ...
        case .inMeeting:
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
```

### How to mute Remote Participant's Audio/Video or Request them to Unmute their Audio/Video

You can call **toggleAudio** and **toggleVideo** to mute/unmute remote participant. Please note that you can't let just anyone mute others. First you need to create a role with the permissions to mute other participants and unmute other participants. Please note that they are **two separate permissions**, one for muting others and one to be able to unmute others. Also, while mute request will succeed directly, an unmute request will be send to remote peer. You can check if you have received an unmute request by checking **changeTrackStateRequests** property on Room Model instance.

Example: Teacher wants to mute a student named 'Pawan''s audio (which is currently unmuted)

```swift
guard let studentPeerModel = (roomModel.peerModels.first{$0.name == "Pawan"}) else { return }
try await studentPeerModel.toggleAudio()
```

Example: Teacher wants to request student named 'Pawan' to unmute their video (which is currently muted)

```swift
// Teacher's side - Toggle student peer model's video
guard let studentPeerModel = (roomModel.peerModels.first{$0.name == "Pawan"}) else { return }
try await studentPeerModel.toggleVideo()

...

// Student's side - Observe changeTrackStateRequests and unmute requested tracks

VStack {
  ...
}
.onChange(of: roomModel.changeTrackStateRequests) { changeTrackStateRequests in
                
    changeTrackStateRequests.forEach { request in
        if let trackModel = roomModel.localPeerModel?.trackModels.first(where: {$0.track == request.track}) {
            if trackModel.isMute {
                Task {
                    try await trackModel.toggleMute()
                }
            }
        }
    }
    
    roomModel.changeTrackStateRequests.removeAll()
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

### How to receive messages from other participants

You can access received messages from **messages** property of RoomModel like following:

```swift
roomModel.messages
```

Example: show list of all received messages.

```swift
List {
    ForEach(roomModel.messages, id: \.self) { hmsMessage in
        Text(hmsMessage.message)
    }
}
```

# How to share iOS screen of local user

You need to follow following steps to be able to share screen from iOS app:

1. Make a new **Broadcast Upload Extension** target from Xcode. This target will be embedded into your application. Xcode automatically sets everything up if you use Xcode template named **Broadcast Upload Extension** to create the target.
2. Add **App Group** capability in your **main app** target as well as in this new **Broadcast Upload Extension** target. Use the same App Group ID in both the targets. Let's assume your app group id is "group.live.100ms.videoapp.roomkit".
3. Xcode creates a **SampleHandler.swift** file in a new folder for your **Broadcast Upload Extension** target. Modify this **SampleHandler.swift** file to contain the following code (delete all the code in **SampleHandler.swift** file and paste the following code):

```swift
import HMSBroadcastExtensionSDK

class SampleHandler: HMSBroadcastSampleHandler {
    
    override var appGroupId: String {
        "group.live.100ms.videoapp.roomkit"
    }
}
```

Where "group.live.100ms.videoapp.roomkit" is the app group ID of your app group that created in step 2. Make sure to replace it with your App Group ID string.

5. With the above steps completed, let your RoomModel instance know about your App Group ID like below:

```swift
@ObservedObject var roomModel = HMSRoomModel(roomCode: "qdw-mil-sev", options: .init(appGroupName: "group.live.100ms.videoapp.roomkit"))
```

6. At this point you are ready to share screen of local iOS user. You can use the following code to make a button to start screen sharing from inside your app UI:

```swift
import SwiftUI
import HMSRoomModels
import ReplayKit

struct RoomModelStandaloneExample: View {
    
    @ObservedObject var roomModel = HMSRoomModel(roomCode: "qdw-mil-sev", options: .init(appGroupName: "group.live.100ms.videoapp.roomkit"))
    
    @StateObject var broadcastPickerView = {
        let picker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        picker.showsMicrophoneButton = false
        return picker
    }()
    
    var body: some View {
        
        switch roomModel.roomState {
        case .notJoined, .leftMeeting:
            // Button to join the room
            ...
        case .inMeeting:
            VStack {
                List {
                    
                    // If a participant is sharing their screen, show their screen at the top of the list
                    ...
                        
                    // Render video of each peer in the call
                    ...
                }
                
                HStack {
                    
                    // Toggle local user's mic
                    ...
                    
                    // Toggle local user's camera
                    ...

                    // Share local user's screen from iOS
                    if roomModel.userCanShareScreen {
                        Image(systemName: "rectangle.inset.filled.and.person.filled")
                            .onTapGesture {
                                for subview in broadcastPickerView.subviews {
                                    if let button = subview as? UIButton {
                                        button.sendActions(for: UIControl.Event.allTouchEvents)
                                    }
                                }
                            }
                            .onAppear() {
                                broadcastPickerView.preferredExtension = "live.100ms.videoapp.roomkit.Screenshare"
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

Where "live.100ms.videoapp.roomkit.Screenshare" is the bundle id of your **Broadcast Upload Extension** target.


# How to Store Common Objects/Information in the Room that is Shared across all Participants

Room Model instance exposes a shared dictionary called **sharedStore**. You can use this to store any objects or primitives and they will be available to all participants in the room. You store key value pairs to this dictionary like following.

Example

### How to store Participant's ID in Shared Storage of the Room so that Everyone in the Meeting can access this ID

```swift
guard let highlightedStudent = (roomModel.peerModels.first{$0.name == "Pawan"}) else { return }
roomModel.sharedStore["Highlighted Participant ID"] = highlightedStudent.id
```

### How would other Participants use this Shared ID

Step 1. Make sure that room model observes this key like following:

```swift
roomModel.beginObserving(keys: ["Highlighted Participant ID"])
```

You generally do this at the start of the meeting, so that you can begin observing any changes for that key. If at any point in the call, you want to stop observing changes for a particular key call **stopObserving(keys:)** method passing an array of keys that you no more want to observe.

Step 2. Display highlighted student

```swift
VStack {
    if let highlightedStudentID = roomModel.sharedStore?["Highlighted Participant ID"] as? String,
       let highlightedStudent = roomModel.peerModels.first(where: {$0.id == highlightedStudentID}) {
        
           HMSVideoTrackView(peer: highlightedStudent)
    }
}
```

Note that **sharedStore** dictionary is **Published** property of room model, thus any changes in this dictionary values reflect in your SwiftUI views automatically.

# How to Attach Objects/Information to a Participant object in the Meeting so that All Participants can Access it

Peer Model instance exposes a shared dictionary called **metadata**. You can use this to store any objects or primitives and they will get attached to that peer. And will be available to all participants in the room. You store key value pairs to this dictionary like following.

Example

### How to attach a link to Particiapnt's Avatar image in Metadata of the Participant so that Everyone in the Meeting can show the Avatar for that Participant.

```swift
roomModel.localPeerModel?.metadata["Avatar Image URL"] = /* url string to avatar image */
```

### How would other Participants access this attached Avatar on a Peer and show it with their Video Tile

```swift
// Render video of each peer in the call
ForEach(roomModel.peerModels) { peerModel in
    VStack {
        if let urlString = peerModel.metadata["Avatar Image URL"] as? String, let url = URL(string: urlString) {
            AsyncImage(url: url)
        }
        HMSVideoTrackView(peer: peerModel)
            .frame(height: 200)
    }
}
```

Note that **metadata** dictionary is **Published** property of peer model, thus any changes in this dictionary values reflect in your SwiftUI views automatically.


# Other Functionalities

#### Preview the Room

Preview screen is a frequently used UX element which allows users to check if their input devices are working properly and set the initial state (mute/unmute) of their audio and video tracks before joining.

You call preview method on the Room model instance to preview the room. You can optionally pass the name of the participant in the preview method.

```swift
roomModel.preview(userName: /*pass participant's name as string here*/)
```


#### Switch Camera (Front/Back)

```swift
try await roomModel.switchCamera()
```

#### Change local participant's name

```swift
try await roomModel.changeUserName(/* new name as string */)
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
