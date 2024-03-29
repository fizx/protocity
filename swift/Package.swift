// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Protocity",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Protocity",
            targets: ["Protocity"]),
    ],
    dependencies: [
        .package(url: "https://github.com/fizx/Algorithm.git", from: "2.2.0"),
        .package(url: "https://github.com/grpc/grpc-swift", from: "0.6.0"),
        .package(url: "https://github.com/Swinject/Swinject", from: "2.5.0"),
        .package(url: "https://github.com/apple/swift-nio", from: "1.0.0"),
        .package(url: "https://github.com/Swinject/SwinjectAutoregistration", from: "2.5.0"),
        
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Protocity",
            dependencies: ["Algorithm", "SwiftGRPC", "Swinject", "SwinjectAutoregistration", "NIO"]),
        .testTarget(
            name: "ProtocityTests",
            dependencies: ["Protocity"],
            path: "Tests"),
    ]
)
