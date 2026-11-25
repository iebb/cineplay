// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "cineplay_pip",
  platforms: [.iOS("12.0")],
  products: [
    .library(name: "cineplay-pip", targets: ["cineplay_pip"])
  ],
  targets: [
    .target(
      name: "cineplay_pip",
      linkerSettings: [
        .linkedFramework("AVFoundation"),
        .linkedFramework("AVKit")
      ]
    )
  ]
)
