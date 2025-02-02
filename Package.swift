// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SQLPackage",
    platforms: [.macOS(.v12),
    .iOS(.v13),
    .tvOS(.v10),
    .watchOS(.v5)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SQLDataAccess",
            targets: ["SQLDataAccess"]),
        .library(
        name: "DataManager",
        targets: ["DataManager"]),
        .library(
        name: "Sqldb",
        targets: ["Sqldb"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        //.package(url: "git@github.com:apple/swift-log.git", from: "1.4.0"),
        .package(url: "git@github.com:Nike-Inc/Willow.git", from: "6.0.0"),
        .package(url: "git@github.com:tristanhimmelman/ObjectMapper.git", from: "4.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.

        .target(
            name: "SQLDataAccess",
            dependencies: [.product(name:"Willow", package:"Willow"),"ObjectMapper"],path:"Sources/SQLDataAccess"),
        .target(name:"DataManager",
            dependencies:["SQLDataAccess"],
            path:"Sources/DataManager"),
        .target(name:"Sqldb",
            dependencies:[],
            path:"Sources/Sqldb"),
        .testTarget(
            name: "SQLPackageTests",
            dependencies: ["SQLDataAccess"]),
    ],
    swiftLanguageVersions: [.v5]
)
