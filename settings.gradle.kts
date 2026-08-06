pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "mobile-fortress"

// The Gradle root now lives at the repo root (workspace-style, alongside
// package.json's npm workspaces and docs/mkdocs.yml) so `./gradlew <task>`
// works from anywhere in the repo without a `cd android/` or `-p android`.
// The Android app module itself still lives at android/app/ — only this
// wrapper/settings/build-script trio moved up.
include(":app")
project(":app").projectDir = file("android/app")
