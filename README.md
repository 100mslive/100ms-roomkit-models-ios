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

```swift
// Initialize with [room-code](https://www.100ms.live/docs/get-started/v2/get-started/prebuilt/room-codes/overview)
let roomModel = HMSRoomModel(roomCode: /*pass room code as string here*/)
```

```swift
// Initialize with [auth-token](https://www.100ms.live/docs/get-started/v2/get-started/security-and-tokens#auth-token-for-client-sdks)
let roomModel = HMSRoomModel(token: /*pass role's auth token as string here*/)
```

## Example usage
