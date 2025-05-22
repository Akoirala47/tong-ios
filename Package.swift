// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Tong",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Tong",
            targets: ["Tong"]),
    ],
    dependencies: [
        // Dependencies for Supabase
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "0.3.0"),
        
        // Audio recording and playback
        .package(url: "https://github.com/AudioKit/AudioKit.git", from: "5.3.0"),
        
        // Image caching and loading
        .package(url: "https://github.com/kean/Nuke.git", from: "10.0.0"),
        
        // For markdown content rendering
        .package(url: "https://github.com/gonzalezreal/MarkdownUI.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Tong",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "AudioKit", package: "AudioKit"),
                .product(name: "Nuke", package: "Nuke"),
                .product(name: "MarkdownUI", package: "MarkdownUI")
            ]),
        .testTarget(
            name: "TongTests",
            dependencies: ["Tong"]),
    ]
) 