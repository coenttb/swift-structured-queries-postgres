// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-structured-queries-postgres",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "StructuredQueriesPostgres",
            targets: ["StructuredQueriesPostgres"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-structured-queries", from: "0.7.0"),
        .package(url: "https://github.com/vapor/postgres-nio", from: "1.21.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.9.0"),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.5.0"),
        .package(url: "https://github.com/coenttb/swift-environment-variables", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "StructuredQueriesPostgres",
            dependencies: [
                .product(name: "StructuredQueries", package: "swift-structured-queries"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
            ]
        ),
        .testTarget(
            name: "StructuredQueriesPostgresTests",
            dependencies: [
                "StructuredQueriesPostgres",
                .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
                .product(name: "EnvironmentVariables", package: "swift-environment-variables"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("MemberImportVisibility"),
]

for index in package.targets.indices {
    package.targets[index].swiftSettings = swiftSettings
}



