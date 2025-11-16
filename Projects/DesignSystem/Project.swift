import ProjectDescription



let project = Project(
    name: "DesignSystem",
    organizationName: "Den",
    packages: [
    ],
    targets: [
        Target.target(
            name: "DesignSystem",
            destinations: [.iPhone, .iPad],
            product: .framework,
            bundleId: "com.den.growtimer.designsystem",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            resources: ["Resources/**/*.xcassets",
                        "Resources/**/*.ttf",
                        "Resources/**/*.otf",
                       ],
            dependencies: [
                .project(target: "ThirdPartyLibrary", path: "../ThirdPartyLibrary"),
            ],
        ),
        Target.target(
            name: "DesignSystemTests",
            destinations: [.iPhone, .iPad],
            product: .unitTests,
            bundleId: "com.den.growtimer.designsystem.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "DesignSystem")
            ]
        )
    ]
)
