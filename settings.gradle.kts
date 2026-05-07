@Suppress("LocalVariableName")
val mod_project: String by settings

rootProject.name = mod_project

pluginManagement {
	@Suppress("LocalVariableName")
	val loom_version: String by settings

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
