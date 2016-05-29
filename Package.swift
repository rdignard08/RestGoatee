import PackageDescription

let package = Package(
    name: "RestGoatee",
    targets: [
        Target(name: "RestGoatee")
    ],
    dependencies: [
        .Package(url: "https://github.com/rdignard08/RestGoatee-Core.git",
                 majorVersion: 2.3),
        .Package(url: "https://github.com/AFNetworking/AFNetworking.git",
                 majorVersion: 3)
    ]
)

