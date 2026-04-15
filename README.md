## fabric-template

My personal template for Fabric mods. Supports at least every non-snapshot Minecraft release since 1.14.

This repo is structured using one revision for each supported version.

- **It is constantly and aggressively rebased by Jujutsu**, so the only reliable way to refer to revisions is by their Jujutsu change ID.
- There may or may not be revisions for snapshots.

Note that Jujutsu is highly recommended for working with this repository, because Git does not support

```toml
[merge]
hunk-level = 'word'
```

which is required for the `gradle.properties` diffs.

Revisions are standardized on the exact same project structure:

- Kotlin DSL for `build.gradle.kts`;
- a simple `ModInitializer` as the mod's only source code;
- `run_server` as a separate directory;
- accepted `eula.txt`;
- customized `options.txt` and `server.properties`;
- and IntelliJ run configurations generated on IDE sync.

The purpose of the repository is to make porting and backporting my mods easier. The idea is that by making it very easy for me to test across multiple versions, it will become much easier for me to support multiple versions. Less grunt work.

- `./gradlew runClient` runs the client **without** the test mod (`src/test`).
- `./gradlew runTestClient` runs the client **with** the test mod (`src/test`).

Mod identity (project name, package, class name, mod ID, etc.) is defined entirely in `gradle.properties`:

- The build automatically reflects changes to those properties.
- The `TEMPLATE_PACKAGE` package is automatically resolved to `mod_group.mod_package` at build time.
- This works both for IntelliJ's run configurations as well as for `./gradlew runClient` (or `runServer`) and `./gradlew build`.

I accept issues and review pull requests.
