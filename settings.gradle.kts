@Suppress("LocalVariableName")
val mod_project = providers.gradleProperty("mod_project").get()

rootProject.name = mod_project

pluginManagement {
	@Suppress("LocalVariableName")
	val loom_version = providers.gradleProperty("loom_version").get()

	repositories {
		maven {
			name = "LocalMaven"
			url = uri("file://${System.getProperty("user.home")}/maven")
		}

		maven {
			name = "Fabric"
			url = uri("https://maven.fabricmc.net/")
		}

		mavenCentral()
		gradlePluginPortal()
	}

	plugins {
		id("fabric-loom") version loom_version
	}
}
