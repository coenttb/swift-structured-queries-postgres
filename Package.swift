// swift-tools-version: 6.1

import CompilerPluginSupport
import PackageDescription

#if canImport(FoundationEssentials)
    import FoundationEssentials
#else
    import Foundation
#endif

let package = Package(
    name: "swift-structured-queries-postgres",
    platforms: [
        .iOS(.v13),
        .macOS(.v13)
        //        .tvOS(.v13),
        //        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "StructuredQueriesCore",
            targets: ["StructuredQueriesCore"]
        ),
        .library(
            name: "StructuredQueriesPostgres",
            targets: ["StructuredQueriesPostgres"]
        ),
        .library(
            name: "StructuredQueriesPostgresTestSupport",
            targets: ["StructuredQueriesPostgresTestSupport"]
        ),
        .library(
            name: "StructuredQueriesPostgresSupport",
            targets: ["StructuredQueriesPostgresSupport"]
        ),
    ],
    traits: [
        .trait(
            name: "StructuredQueriesPostgresCasePaths",
            description: "Introduce enum table support to StructuredQueries."
        ),
        .trait(
            name: "StructuredQueriesPostgresTagged",
            description: "Introduce StructuredQueries conformances to the swift-tagged package."
        ),
        .trait(
            name: "StructuredQueriesPostgresSQLValidation",
            description:
                "Enable SQL syntax validation against PostgreSQL using postgres-nio. Heavy dependency - only enable for validation testing."
        ),
        .default(
            enabledTraits: [
                "StructuredQueriesPostgresCasePaths",
//                "StructuredQueriesPostgresTagged",
                "StructuredQueriesPostgresSQLValidation",
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.8.1"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.3"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.4"),
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", exact: "1.6.1"),
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"603.0.0"),
        .package(url: "https://github.com/vapor/postgres-nio", from: "1.22.0"),
    ],
    targets: [
        .target(
            name: "StructuredQueriesCore",
            dependencies: [
                "StructuredQueriesPostgresSupport",
                .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
                .product(
                    name: "CasePaths",
                    package: "swift-case-paths",
                    condition: .when(traits: ["StructuredQueriesPostgresCasePaths"])
                ),
                .product(
                    name: "Tagged",
                    package: "swift-tagged",
                    condition: .when(traits: ["StructuredQueriesPostgresTagged"])
                ),
            ]
        ),
        .target(
            name: "StructuredQueriesPostgres",
            dependencies: [
                "StructuredQueriesCore",
                "StructuredQueriesPostgresMacros",
            ]
        ),
        .macro(
            name: "StructuredQueriesPostgresMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ],
            exclude: ["Symbolic Links/README.md"]
        ),
        .target(
            name: "StructuredQueriesPostgresTestSupport",
            dependencies: [
                "StructuredQueriesCore",
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
                .product(
                    name: "PostgresNIO",
                    package: "postgres-nio",
                    condition: .when(traits: ["StructuredQueriesPostgresSQLValidation"])
                ),
            ]
        ),
        .target(
            name: "StructuredQueriesPostgresSupport",
            dependencies: []
        ),
        .testTarget(
            name: "StructuredQueriesPostgresMacrosTests",
            dependencies: [
                "StructuredQueriesPostgres",
                "StructuredQueriesPostgresMacros",
                .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
                .product(name: "MacroTesting", package: "swift-macro-testing"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "StructuredQueriesPostgresTests",
            dependencies: [
                "StructuredQueriesPostgres",
                "StructuredQueriesPostgresTestSupport",
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
        .testTarget(
            name: "READMEExamplesTests",
            dependencies: [
                "StructuredQueriesPostgres",
                "StructuredQueriesPostgresTestSupport",
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("MemberImportVisibility")
]

for index in package.targets.indices {
    package.targets[index].swiftSettings = swiftSettings
}
