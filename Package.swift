// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DiskSpaceMenu",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "DiskSpaceMenu", targets: ["DiskSpaceMenu"])],
    targets: [.executableTarget(name: "DiskSpaceMenu")]
)
