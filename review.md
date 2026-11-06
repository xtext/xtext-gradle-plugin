# Review: xtext-gradle-plugin PR #221 — "Gradle9 java21 modernization"

- **PR:** https://github.com/xtext/xtext-gradle-plugin/pull/221
- **Branch:** `gradle9-java21-modernization`
- **Commit reviewed:** `992e9d5`
- **Review date:** 2026-11-06
- **Review type:** local code review + build/test verification (no changes made to the PR branch)

## Verdict

The core migration is correct and well done — the build is green everywhere and the two earlier Copilot findings are genuinely fixed. However, there are a few regressions in behavior and documentation that should be addressed before merge, plus test gaps that allowed those regressions through.

**Recommendation: request changes** for findings 1 and 3 (behavioral correctness). Findings 4 and 5 can be follow-ups but are cheap to fix now. Findings 2 and 6 undercut the PR's stated goals and should be fixed in this PR.

---

## Verification performed

Everything below was run locally against the PR branch, not inferred from the diff.

| Check | Result |
| --- | --- |
| `./gradlew :xtext-gradle-plugin:test :xtext-gradle-plugin:validatePlugins` | Green, 32 tests |
| `./gradlew minimumIntegrationTest` | Green, 54 tests (Xtext 2.41) |
| `./gradlew latestIntegrationTest` | Green, 54 tests (Xtext 2.44) |
| `./gradlew build` | Green |
| Plugin jar bytecode | Java 21 (`major version: 65`) |
| Version resource in jar | `minimumXtextVersion=2.41.0` embedded correctly |
| CI (GitHub Actions) | Green on Linux, Windows, macOS for `992e9d5` |

Additionally verified:

- `EclipseModel.synchronizationTasks(Object...)`, `TaskCollection`, `ObjectFactory.fileTree()`, and `AbstractTestTask.getFailOnNoDiscoveredTests()` all exist with the signatures used in the PR (Gradle 9.8.1).
- `build` triggers `xtextEclipseSettings` via the `classes` hook (proven with a temporary test, since reverted; working tree left clean).
- `./gradlew pTML --dry-run` resolves to `publishToMavenLocal` (writes to `~/.m2`, not `repox/`); no `repox` repository or task is configured anywhere.
- The outer build still emits a Gradle 9 deprecation from bootstrap plugin 4.0.0 during `generateIntegTestXtext`: `Invocation of Task.project at execution time has been deprecated`.
- `battila7/get-version-action@v2` declares `runs.using: node12`.
- Only `gradle/wrapper/gradle-wrapper.properties` was updated; `gradle-wrapper.jar` was not. The wrapper still works.

---

## Major findings

### 1. `classes` now rewrites user-owned `.settings` files on every build

**File:** `xtext-gradle-plugin/src/main/java/org/xtext/gradle/XtextBuilderPlugin.xtend:174-180`

`xtextEclipseSettings` is wired into `classes`. As a result, `./gradlew build` / `./gradlew classes` mutates `.settings/` files that are typically checked into the repository — including on CI where nothing consumes them. This goes beyond "generate on demand": it can produce dirty working trees and unexpected diffs for Buildship users.

The trade-off is also asymmetric. `./gradlew eclipse` **no longer** triggers settings generation for non-Buildship users, because only `classes` and `synchronizationTasks` are hooked. Users following the documented `eclipse` workflow lose files they used to get.

Suggested fix: gate the `classes` wiring behind a property, or retain the `eclipse`/`cleanEclipse` wiring so the non-Buildship workflow keeps working.

### 2. Claims of lazy task registration are not true

**File:** `xtext-gradle-plugin/src/main/java/org/xtext/gradle/XtextBuilderPlugin.xtend:131,133`

```groovy
val javaCompile = project.tasks.getByName(javaSourceSet.compileJavaTaskName) as JavaCompile
...
val generatorTask = project.tasks.getByName(xtextSourceSet.generatorTaskName) as XtextGenerate
```

Both calls realize tasks eagerly at configuration time, contradicting the lazy-registration motivation stated in the PR and its code comments. This also runs inside `sourceSets.all`, so the cost scales with the number of source sets.

Suggested fix: use `tasks.named(...)` and wire `Provider`s instead of resolved task instances.

### 3. Stale test defaults make local IDE runs meaningless

**Files:**

- `xtext-gradle-plugin/src/integTest/java/org/xtext/gradle/test/AbstractIntegrationTest.xtend:16` — defaults `xtext.version` to `2.17.1`, far below the new `minimumXtextVersion=2.41.0`.
- `xtext-gradle-plugin/src/integTest/java/org/xtext/gradle/test/GradleBuildTester.xtend:20` — defaults `gradle.version` to `7.1`, which cannot run Gradle-9-era plugin metadata and does not match the wrapper (9.8.1).

CI passes these properties explicitly, so only contributors running tests from an IDE are affected — but that is exactly when the confusion is most costly. Align the defaults with `gradle.properties`.

---

## Minor findings

### 4. README is inaccurate in three places

- It claims `pTML` publishes to `repox/`. No `repox` repository or task exists; `pTML` is Gradle's abbreviation for `publishToMavenLocal`, which writes to `~/.m2/repository`.
- It says `org.eclipse.xtend` coordinates are no longer version-aligned. They still are — `XtextBuilderPlugin.xtend:96` explicitly aligns both `org.eclipse.xtext` and `org.eclipse.xtend`.
- The Java requirement says 17+. Because the plugin bytecode is Java 21, the Gradle **daemon** must be Java 21+. A Java 17 daemon cannot load the plugin, so "17+" sends users down a bad path.

### 5. Release workflow does not verify the published artifact

**File:** `.github/workflows/release.yml`

- The `Verify` step omits `-PreleaseVersion`, so it verifies a build that is not the exact artifact being published.
- `battila7/get-version-action@v2` still runs on `node12`, which GitHub has been sunsetting. Worth bumping while other actions are modernized.

### 6. Coverage gap around the actual `.settings` change

- `settingsSurviveClean` tests `clean`, which never deleted `.settings` on `master`. The behavior this PR actually changed was `cleanEclipse`, so the test does not cover it.
- There is no test asserting that `build` / `classes` generates `.settings`, which is precisely the new behavior described in finding 1.

Suggested fix: add both tests.

---

## Nits

- `XtextBuilderPlugin.xtend:117` still eager-resolves `project.layout.buildDirectory.get()` in `configureDefaults`. A `Provider<Directory>` would keep configuration-cache friendliness.
- Plain-language projects (no Java plugin) derive `javaSourceLevel` from the daemon JVM (`XtextGenerate.xtend:114`). With a JDK 25 daemon plus Xtext 2.41 this now fails explicitly — correct behavior, but the error message is worth checking. Note that Xtext only supports source levels 8/9/10/11/17/21/25, so any other daemon JVM will break.
- The outer build still emits a Gradle 9 deprecation from bootstrap plugin 4.0.0 during `generateIntegTestXtext` (`Invocation of Task.project at execution time`). Not blocking, but the outer build cannot move to Gradle 10 until bootstrap is 5.x.

---

## What is good

- Both earlier Copilot findings are properly addressed: the `classes` lookup is lazy (`matching(...).configureEach`), and `XtextEclipseSettings` resolves symlink-safe relative paths.
- Gradle 9 API usage checks out: `EclipseModel.synchronizationTasks(Object...)`, `ObjectFactory.fileTree()`, and `AbstractTestTask.failOnNoDiscoveredTests`.
- `failOnNoDiscoveredTests` is a solid addition — it would have caught silently-empty test matrices.
- The md5→sha256 migration in `XtextGradleBuilder` and the build-time version-resource embedding are both clean.

---

## Suggested merge checklist

- [ ] Decide on the `.settings` lifecycle wiring (findings 1 and 6)
- [ ] Replace eager `getByName` with `tasks.named` (finding 2)
- [ ] Align integration-test version defaults with `gradle.properties` (finding 3)
- [ ] Correct the README statements (finding 4)
- [ ] Pass `-PreleaseVersion` in release verification; bump Node 12 action (finding 5)
- [ ] Optional: migrate `buildDirectory.get()` to a `Provider` (nit)
