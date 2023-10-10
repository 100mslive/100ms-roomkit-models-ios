# 🎉 100ms Meeting Room Models 🚀
Introducing meeting room models that simplify SwiftUI based application development using 100ms SDK
  
## Pre-requisites
- Xcode 14 or higher
- iOS 15 or higher

## Integration

You can integrate RoomModels SDK into your project using Swift Package Manager (SPM). Follow these steps:

1. Open your Xcode project.
2. Navigate to `File` > `Add Package Dependency`.
3. In the dialog that appears, enter the following URL as the package source: https://github.com/100mslive/100ms-roomkit-models-ios
4. Click `Next` and follow the prompts to add the package to your project.

## RoomModels Basics

### Import SDK
You import the RoomModels SDK with following import statement

```swift
import HMSRoomModels
```

### Create a Room Model

You can create a reactive model of the room with either a [room-code](https://www.100ms.live/docs/get-started/v2/get-started/prebuilt/room-codes/overview) or an [auth-token](https://www.100ms.live/docs/get-started/v2/get-started/security-and-tokens#auth-token-for-client-sdks) like below:

```swift
// Initialize with room-code
let roomModel = HMSRoomModel(roomCode: /*pass room code as string here*/)
```

```swift
// Initialize with auth-token
let roomModel = HMSRoomModel(token: /*pass role's auth token as string here*/)
```

## Preview the Room

Preview screen is a frequently used UX element which allows users to check if their input devices are working properly and set the initial state (mute/unmute) of their audio and video tracks before joining.

You call preview method on the Room model instance to preview the room. You can optionally pass the name of the participant in the preview method.

```swift
let roomModel.preview(userName: /*pass participant's name as string here*/)
```

## Join the Room

To join and interact with others in audio or video call, the user needs to join a room.

You call join method on Room Model instance to join the room. You can optionally pass the name of the participant in the join method.

```swift
let roomModel.join(userName: /*pass participant's name as string here*/)
```
