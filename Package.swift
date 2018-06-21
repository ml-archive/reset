// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Reset",
    products: [
        .library(name: "Reset", targets: ["Reset"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nodes-vapor/submissions.git", .branch("master")),
        .package(url: "https://github.com/nodes-vapor/sugar.git", .branch("vapor-3")),
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0-rc"),
        .package(url: "https://github.com/vapor/fluent.git", from: "3.0.0-rc"),
        .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0-rc"),
        .package(url: "https://github.com/vapor/leaf.git", from: "3.0.0-rc"),
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0")
    ],
    targets: [
        .target(name: "Reset", dependencies: [
            "Authentication",
            "Fluent",
            "JWT",
            "Leaf",
            "Sugar",
            "Vapor"
        ]),
        .testTarget(name: "ResetTests", dependencies: ["Reset"]),
    ]
)
