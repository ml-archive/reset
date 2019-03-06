// swift-tools-version:4.1
import PackageDescription

let package = Package(
    name: "Reset",
    products: [
        .library(name: "Reset", targets: ["Reset"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nodes-vapor/submissions.git", from: "2.0.0-rc"),
        .package(url: "https://github.com/nodes-vapor/sugar.git", from: "4.0.0-rc"),
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0")
    ],
    targets: [
        .target(name: "Reset", dependencies: [
            "Authentication",
            "Fluent",
            "JWT",
            "Leaf",
            "Sugar",
            "Submissions",
            "Vapor"
        ]),
        .testTarget(name: "ResetTests", dependencies: ["Reset"]),
    ]
)
