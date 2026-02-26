import java.util.Properties

val localProperties: Properties = Properties().also { properties ->
    val localPropertiesFile = file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { properties.load(it) }
    }
}

fun Project.readStringProperty(vararg keys: String): String? {
    for (key in keys) {
        val fromGradleProperty = providers.gradleProperty(key).orNull
        if (!fromGradleProperty.isNullOrBlank()) return fromGradleProperty

        val fromEnv = System.getenv(key)
        if (!fromEnv.isNullOrBlank()) return fromEnv

        val fromLocalProperties = localProperties.getProperty(key)
        if (!fromLocalProperties.isNullOrBlank()) return fromLocalProperties
    }
    return null
}

val mapboxRegistryToken: String? = rootProject.readStringProperty(
    // Newer Mapbox SDK registry token key used by mapbox_maps_flutter
    "SDK_REGISTRY_TOKEN",
    // Older/common Mapbox download token key
    "MAPBOX_DOWNLOADS_TOKEN",
    // Convenience keys for local.properties
    "sdk.registry.token",
    "mapbox.downloads.token",
)

// mapbox_maps_flutter's Android build expects this property on the root project.
rootProject.extra["SDK_REGISTRY_TOKEN"] = mapboxRegistryToken ?: ""
// Some Mapbox build scripts still look for MAPBOX_DOWNLOADS_TOKEN.
rootProject.extra["MAPBOX_DOWNLOADS_TOKEN"] = mapboxRegistryToken ?: ""

if (mapboxRegistryToken.isNullOrBlank()) {
    logger.warn(
        "Mapbox Android build: missing SDK registry token. " +
            "Add `SDK_REGISTRY_TOKEN=...` to android/local.properties (recommended) " +
            "or set environment variable SDK_REGISTRY_TOKEN (or MAPBOX_DOWNLOADS_TOKEN)."
    )
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
