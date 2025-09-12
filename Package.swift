// swift-tools-version: 6.1

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "swift-structured-queries-postgres",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "StructuredQueriesPostgres",
            targets: ["StructuredQueriesPostgres"]
        ),
        .library(
            name: "StructuredQueriesPostgresCore",
            targets: ["StructuredQueriesPostgresCore"]
        ),
        .library(
            name: "StructuredQueriesPostgresTestSupport",
            targets: ["StructuredQueriesPostgresTestSupport"]
        )
    ],
    traits: [
        .trait(
            name: "StructuredQueriesPostgresTagged",
            description: "Introduce StructuredQueries conformances to the swift-tagged package.",
            enabledTraits: []
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.8.1"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.3"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.4"),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.5.2"),
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"602.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
    ],
    targets: [
        .target(
            name: "StructuredQueriesPostgres",
            dependencies: [
                "StructuredQueriesPostgresCore",
                "StructuredQueriesPostgresMacros",
            ]
        ),
        .target(
            name: "StructuredQueriesPostgresCore",
            dependencies: [
                .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
                .product(
                    name: "Tagged",
                    package: "swift-tagged",
                    condition: .when(traits: ["StructuredQueriesTagged"])
                ),
            ],
            exclude: ["Symbolic Links/README.md"]
        ),
        .macro(
            name: "StructuredQueriesPostgresMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax")
            ],
            exclude: ["Symbolic Links/README.md"]
        ),
        .target(
            name: "StructuredQueriesPostgresTestSupport",
            dependencies: [
                "StructuredQueriesPostgresCore",
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "DependenciesTestSupport", package: "swift-dependencies")
            ]
        ),
        .target(
            name: "StructuredQueriesPostgresSupport",
            dependencies: [

            ]
        ),
        .testTarget(
            name: "StructuredQueriesPostgresMacrosTests",
            dependencies: [
                "StructuredQueriesPostgres",
                "StructuredQueriesPostgresMacros",
                .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
                .product(name: "MacroTesting", package: "swift-macro-testing")
            ]
        ),
        .testTarget(
            name: "StructuredQueriesPostgresTests",
            dependencies: [
                "StructuredQueriesPostgres",
                "StructuredQueriesPostgresTestSupport",
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("MemberImportVisibility")
    // .unsafeFlags([
    //   "-Xfrontend",
    //   "-warn-long-function-bodies=50",
    //   "-Xfrontend",
    //   "-warn-long-expression-type-checking=50",
    // ])
]

for index in package.targets.indices {
    package.targets[index].swiftSettings = swiftSettings
}

#if !os(Windows)
// Add the documentation compiler plugin if possible
package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
)
#endif
