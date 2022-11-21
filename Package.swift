// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "ImageFetcherController",
    
	platforms: [.iOS("15.0")],
    products: [
        .library(
            name: "ImageFetcherController",
            targets: ["ImageFetcherController"]),
    ],

    dependencies: [],
    targets: [
        .target(
            name: "ImageFetcherController",
            dependencies: [])
    ]
)
