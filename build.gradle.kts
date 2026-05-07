@file:Suppress("PropertyName")

import com.google.gson.Gson
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import com.google.gson.stream.JsonWriter
import java.io.StringWriter

buildscript {
	@Suppress("LocalVariableName")
	val loader_version: String by project

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
	}

	dependencies {
		classpath("net.fabricmc:fabric-loader:$loader_version")
	}
}

plugins {
	id("net.fabricmc.fabric-loom")
	`maven-publish`
}

val minecraft_version: String by project
val loader_version: String by project
val mod_dependencies: String by project
val fabric_api_version: String by project
val fabric_api_modules: String by project
val java_version: String by project
val java_target: String by project

val mod_group: String by project
val mod_package: String by project
val mod_class: String by project
val mod_id: String by project
val mod_name: String by project
val mod_version: String by project
val mod_description: String by project

fun parseModuleList(value: String): List<String> =
	value.split(",").map { it.trim() }.filter { it.isNotEmpty() }

val fabricApiModuleList = parseModuleList(fabric_api_modules)
val modDependencyList = parseModuleList(mod_dependencies)
val addedDepends = fabricApiModuleList + modDependencyList

val mod_full_package = "${mod_group}.${mod_package}"
val mod_full_version = "${mod_version}+${minecraft_version}"

val testmod_id = "${mod_id}-test"
val testmod_full_package = "${mod_full_package}.testing"
val testmod_class = "${mod_class}Test"
val testmod_name = "$mod_name Testing"
val testmod_description = "Testing for $mod_name"
val testmod_added_depends = addedDepends + mod_id

val minecraft_dependency: String = if (minecraft_version.isEmpty()) "" else run {
	val cls = Class.forName("net.fabricmc.loader.impl.game.minecraft.McVersionLookup")
	val getRelease = cls.getMethod("getRelease", String::class.java)
	val normalize = cls.getMethod("normalizeVersion", String::class.java, String::class.java)
	val release = getRelease.invoke(null, minecraft_version) as String
	normalize.invoke(null, minecraft_version, release) as String
}

group = mod_group
version = mod_full_version

repositories {
	maven {
		name = "LocalMaven"
		url = uri("file://${System.getProperty("user.home")}/maven")
	}

	mavenCentral()
}

data class TemplateSubstitution(
	val prefix: String,
	val targetPackage: String,
	val targetClass: String,
	val targetModId: String
)

fun List<TemplateSubstitution>.replaceIn(text: String): String {
	var result = text

	for (sub in this) {
		result = result
			.replace("${sub.prefix}_PACKAGE", sub.targetPackage)
			.replace("${sub.prefix}_CLASSNAME", sub.targetClass)
			.replace("${sub.prefix}_MODID", sub.targetModId)
	}

	return result
}

fun generateTemplatedSources(
	templateDir: File,
	outputDir: File,
	subs: List<TemplateSubstitution>
) {
	val primary = subs.first()
	val packageDir = File(outputDir, primary.targetPackage.replace('.', '/'))
	outputDir.deleteRecursively()
	packageDir.mkdirs()

	templateDir.walkTopDown().filter { it.isFile && it.extension == "java" }.forEach { file ->
		val relativePath = file.relativeTo(templateDir)
		val content = subs.replaceIn(file.readText())
		var fileName = relativePath.path

		for (sub in subs) {
			fileName = fileName.replace("${sub.prefix}_CLASSNAME", sub.targetClass)
		}

		val targetFile = File(packageDir, fileName)
		targetFile.parentFile.mkdirs()
		targetFile.writeText(content)
	}
}

fun postProcessTemplatedResources(
	destinationDir: File,
	subs: List<TemplateSubstitution>,
	deps: List<String>
) {
	destinationDir.walkTopDown()
		.filter { it.name == "fabric.mod.json" || it.name.endsWith(".mixins.json") }
		.forEach { file ->
			var text = subs.replaceIn(file.readText())

			if (file.name == "fabric.mod.json") {
				val parsed = JsonParser.parseString(text).asJsonObject
				val depends = parsed.getAsJsonObject("depends")
					?: JsonObject().also { parsed.add("depends", it) }

				depends.addProperty("minecraft", minecraft_dependency)

				for (id in deps) {
					if (!depends.has(id)) {
						depends.addProperty(id, "*")
					}
				}

				text = StringWriter().also { sw ->
					JsonWriter(sw).use { writer ->
						writer.setIndent("\t")
						Gson().toJson(parsed, writer)
					}

					sw.append('\n')
				}.toString()
			}

			file.writeText(text)
		}

	for (dirName in listOf("data", "assets")) {
		val dir = File(destinationDir, dirName)
		if (dir.isDirectory) {
			dir.walkTopDown()
				.filter { it.isFile && it.extension == "json" }
				.forEach { file ->
					val text = file.readText()
					var replaced = text

					for (sub in subs) {
						replaced = replaced.replace("${sub.prefix}_MODID", sub.targetModId)
					}

					if (replaced !== text) {
						file.writeText(replaced)
					}
				}
		}
	}

	for (sub in subs) {
		destinationDir.walkTopDown()
			.filter { it.isDirectory && it.name == "${sub.prefix}_MODID" }
			.sortedByDescending { it.path.length }
			.forEach { dir -> dir.renameTo(File(dir.parentFile, sub.targetModId)) }
	}
}

fun Copy.configureTemplatedModResources(
	subs: List<TemplateSubstitution>,
	targetModName: String,
	targetModDescription: String,
	deps: List<String>,
) {
	val primary = subs.first()
	val props = mapOf(
		"mod_id" to primary.targetModId,
		"mod_name" to targetModName,
		"mod_version" to mod_full_version,
		"mod_class" to primary.targetClass,
		"mod_description" to targetModDescription,
		"mod_full_package" to primary.targetPackage,
		"java_target" to java_target
	)

	inputs.properties(props)
	inputs.property("minecraft_dependency", minecraft_dependency)
	inputs.property("substitutions", subs.toString())
	inputs.property("added_depends", deps.toString())

	filesMatching(listOf("fabric.mod.json", "*.mixins.json")) {
		expand(props)
	}

	for (sub in subs) {
		rename("${sub.prefix}_MODID\\.(.*\\.)*mixins\\.json", "${sub.targetModId}.$1mixins.json")
	}

	doLast {
		postProcessTemplatedResources(
			destinationDir = destinationDir,
			subs = subs,
			deps = deps,
		)
	}
}

val modSubstitution = TemplateSubstitution(
	prefix = "TEMPLATE",
	targetPackage = mod_full_package,
	targetClass = mod_class,
	targetModId = mod_id,
)

val testmodSubstitution = TemplateSubstitution(
	prefix = "TEST",
	targetPackage = testmod_full_package,
	targetClass = testmod_class,
	targetModId = testmod_id,
)

sourceSets.main {
	java.srcDir("build/generated/sources/mod/java")
}

sourceSets.test {
	java.setSrcDirs(emptyList<File>())
	resources.setSrcDirs(emptyList<File>())
}

val testmodSourceSet = sourceSets.create("testmod") {
	val testJavaDir = file("src/test/java")
	val testResourcesDir = file("src/test/resources")
	java.setSrcDirs(listOfNotNull(testJavaDir.takeIf { it.isDirectory }, file("build/generated/sources/testmod/java")))
	resources.setSrcDirs(listOfNotNull(testResourcesDir.takeIf { it.isDirectory }))
	compileClasspath += sourceSets.main.get().compileClasspath
	runtimeClasspath += sourceSets.main.get().runtimeClasspath
	compileClasspath += sourceSets.main.get().output
	runtimeClasspath += sourceSets.main.get().output
}

dependencies {
	minecraft("com.mojang:minecraft:${minecraft_version}")
	implementation("net.fabricmc:fabric-loader:${loader_version}")

	for (module in fabricApiModuleList) {
		implementation(fabricApi.module(module, fabric_api_version))
	}
}

java {
	toolchain {
		languageVersion = JavaLanguageVersion.of(java_version.toInt())
	}

	sourceCompatibility = JavaVersion.toVersion(java_target)
	targetCompatibility = JavaVersion.toVersion(java_target)

	withSourcesJar()
}

tasks.withType<JavaCompile>().configureEach {
	options.release = java_target.toInt()
}

loom {
	mods {
		register(mod_id) {
			sourceSet(sourceSets.main.get())
		}
		register(testmod_id) {
			sourceSet(testmodSourceSet)
		}
	}

	runConfigs.named("server") {
		runDir = "run_server"
	}

	runConfigs.create("testClient") {
		client()
		ideConfigGenerated(true)
		name = "Test Client"
		source(testmodSourceSet)
		runDir = "run"
	}

	runConfigs.create("testServer") {
		server()
		ideConfigGenerated(true)
		name = "Test Server"
		source(testmodSourceSet)
		runDir = "run_server"
	}
}

publishing {
	publications {
		create<MavenPublication>("mod") {
			artifactId = mod_id
			from(components["java"])
		}
	}

	repositories {
		maven {
			name = "LocalMaven"
			url = uri("file://${System.getProperty("user.home")}/maven")
		}
	}
}

val generateModSources by tasks.registering {
	val templateDir = file("src/main/java/TEMPLATE_PACKAGE")
	val outputDir = layout.buildDirectory.dir("generated/sources/mod/java")
	val subs = listOf(modSubstitution)

	inputs.dir(templateDir)
	inputs.property("substitutions", subs.toString())
	outputs.dir(outputDir)

	doLast {
		generateTemplatedSources(
			templateDir = templateDir,
			outputDir = outputDir.get().asFile,
			subs = subs,
		)
	}
}

val generateTestmodSources by tasks.registering {
	val templateDir = file("src/test/java/TEST_PACKAGE")
	val outputDir = layout.buildDirectory.dir("generated/sources/testmod/java")
	val subs = listOf(testmodSubstitution, modSubstitution)

	onlyIf { templateDir.isDirectory }
	inputs.dir(templateDir).optional(true)
	inputs.property("substitutions", subs.toString())
	outputs.dir(outputDir)

	doLast {
		generateTemplatedSources(
			templateDir = templateDir,
			outputDir = outputDir.get().asFile,
			subs = subs,
		)
	}
}

tasks.compileJava {
	dependsOn(generateModSources)
}

tasks.named<JavaCompile>("compileTestmodJava") {
	dependsOn(generateTestmodSources)
}

tasks.processResources {
	configureTemplatedModResources(
		subs = listOf(modSubstitution),
		targetModName = mod_name,
		targetModDescription = mod_description,
		deps = addedDepends,
	)
}

tasks.named<Copy>("processTestmodResources") {
	configureTemplatedModResources(
		subs = listOf(testmodSubstitution, modSubstitution),
		targetModName = testmod_name,
		targetModDescription = testmod_description,
		deps = testmod_added_depends,
	)
}

tasks.jar {
	exclude("TEMPLATE_PACKAGE/**")
}

tasks.named<Jar>("sourcesJar") {
	dependsOn(tasks.processResources, generateModSources)
	exclude("TEMPLATE_PACKAGE/**")

	val rawResourceDirs = sourceSets.main.get().resources.srcDirs.map { it.absoluteFile }
	exclude { element ->
		val f = element.file.absoluteFile
		rawResourceDirs.any { f.startsWith(it) }
	}

	from(tasks.processResources)
}

afterEvaluate {
	tasks.findByName("ideaSyncTask")?.doFirst {
		val configDir = rootProject.file(".idea/runConfigurations")
		if (configDir.isDirectory) {
			configDir.listFiles { f ->
				f.isFile && f.name.startsWith("Minecraft_") && f.name.endsWith(".xml")
			}?.forEach { it.delete() }
		}
	}
}
