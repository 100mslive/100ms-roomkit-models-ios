// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HMSRoomModels",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "HMSRoomModels",
            targets: ["HMSRoomModels"]),
        .library(
            name: "HMSSDK",
            targets: ["HMSSDK"]),
        .library(
            name: "HMSAnalyticsSDK",
            targets: ["HMSAnalyticsSDK"]),
        .library(
            name: "HMSHLSPlayerSDK",
            targets: ["HMSHLSPlayerSDK"]),
        .library(
            name: "HMSBroadcastExtensionSDK",
            targets: ["HMSBroadcastExtensionSDK"]),
        .library(
            name: "WebRTC",
            targets: ["WebRTC"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/auth0/JWTDecode.swift", from: "3.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "HMSRoomModels",
            dependencies: [.product(name: "JWTDecode", package: "JWTDecode.swift"), .byName(name: "HMSHLSPlayerSDK"), .byName(name: "HMSSDK"), .byName(name: "HMSAnalyticsSDK"), .byName(name: "WebRTC"), .byName(name: "HMSBroadcastExtensionSDK")]
        ),
        .binaryTarget(
            name: "HMSSDK",
            url: "https://github.com/100mslive/100ms-ios-sdk/releases/download/1.16.7/HMSSDK.xcframework.zip",
            checksum: "67228edf837f6a2d7818e4b3ae1d2245ad625392f765f72de6c8024eceec5033"
        ),
        .binaryTarget(
            name: "HMSAnalyticsSDK",
            url: "https://github.com/100mslive/100ms-ios-analytics-sdk/releases/download/0.0.2/HMSAnalyticsSDK.xcframework.zip",
            checksum: "40229908576cac8afab7f9ba8b3bd9b1408f97f7bff63f83dca5b4f60f4378f0"
        ),
        .binaryTarget(
            name: "HMSHLSPlayerSDK",
            url: "https://github.com/100mslive/100ms-ios-hls-sdk/releases/download/0.0.2/HMSHLSPlayerSDK.xcframework.zip",
            checksum: "470932129c8dd358ebbe748bc1e05739f33c642779513fee17e42a117329dce2"
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/100mslive/webrtc-ios/releases/download/1.0.6172/WebRTC.xcframework.zip",
            checksum: "4b4e0d6fe7934deb544ec0c812bf00665c8b57b210573ad58be9e7d7c4c590f6"
        ),
        .binaryTarget(
            name: "HMSBroadcastExtensionSDK",
            url: "https://github.com/100mslive/100ms-ios-broadcast-sdk/releases/download/1.0.0/HMSBroadcastExtensionSDK.xcframework.zip",
            checksum: "589a000dfdc948f938482d8affb333644ccc74300e5c7df2ea1aa887a94ae0b9"
        ),
    ]
)
