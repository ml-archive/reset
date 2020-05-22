// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "reset",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "Reset", targets: ["Reset"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0-rc"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0")
    ],
    targets: [
        .target(name: "Reset", dependencies: [
            .product(name: "JWT", package: "jwt"),
            .product(name: "Vapor", package: "vapor")
        ]),
        .testTarget(name: "ResetTests", dependencies: ["Reset"]),
    ]
)
