# Built-in Bangumi metadata

Bangumi ships inside this fork as an animation metadata source, alongside AniList and MyAnimeList. Install a build of this fork, then select **Bangumi** in Settings → Modules or the Home source menu. No module URL, script download or Bangumi account is required. Metadata and artwork still need network access to Bangumi.

The bundled `Shirox/Resources/Bangumi.json` and `Bangumi.js` are copied into every app target, including iOS, macOS, tvOS and Catalyst. A separate JavaScript runner reads them directly from the app bundle. Updating the bundled source requires an app update; refreshing imported modules does not replace its code. A missing bundled resource produces an error instead of fetching a script remotely.

Home provides score ranking and premiere-date catalogs. Search and title details provide titles, cover art, synopsis, ratings, tags, studios, directors and episodes. A metadata health check never requests a video stream. To watch a title, choose a matching title from an installed playback module using the detail page's playback-source picker.

## Upgrading from the imported module

The built-in source retains the previous Bangumi module identity. Existing source selection and bookmarked metadata titles continue to work. An imported copy is hidden from the source list, and metadata reads always use the bundled version. Older Bangumi modules are classified as metadata even if their manifest used a playback type, so they cannot be selected for streaming or downloads. Other imported metadata modules remain available.

The built-in source is kept separately from user-installed modules. Removing imported modules, restoring backups and switching profiles do not remove the bundled source. Source selection remains a per-profile preference. Bangumi IDs stay namespaced and are not sent as AniList or MyAnimeList IDs.

## Source and validation

The fork starts at upstream commit `398d36715b34a17ec68bfd52d792f7a2e7db06f5`. The complete patch and build workflow are maintained in [quiteQa/shirox-bangumi](https://github.com/quiteQa/shirox-bangumi/tree/main/native).

The earlier imported-module integration passed all four app builds and iOS test-target compilation in [run 40844088237](https://github.com/quiteQa/shirox-bangumi/actions/runs/40844088237). That run's IPA predates the built-in resources and still requires module import. Use a newer successful [metadata build](https://github.com/quiteQa/shirox-bangumi/actions/workflows/shirox-metadata-build.yml) for this version, and download its `metadata-Shirox_iOS` artifact. Unzip and sign `Shirox-metadata-unsigned.ipa` with your own sideloading method. Artifacts require a GitHub login and expire according to retention settings.

The workflow runs the module's 31 offline JavaScript tests, checks localization and icons, builds all four app schemes, compiles iOS tests without starting a simulator, and verifies both Bangumi resources exist in the packaged iOS app. `MetadataModuleTests` additionally covers bundle loading, legacy-module classification, duplicate suppression and source selection after a profile reload.

XCTest has not been executed and real-device behavior has not been verified. Existing libzstd module-import and AppIntents metadata warnings remain. The upstream `TSAudioTimestampsTests` expression is split into intermediate values to avoid a type-check timeout without changing its behavior.

## Verified built-in download

[Download the unsigned iOS artifact](https://github.com/quiteQa/shirox-bangumi/actions/runs/40859332293/artifacts/12891605917) · [Build record](https://github.com/quiteQa/shirox-bangumi/actions/runs/40859332293) · [Strict SwiftLint](https://github.com/quiteQa/shirox-bangumi/actions/runs/40859332348)

Source commit `50b31671a002842708427de05fbb68098f6ce016` passed all four app builds and arm64 iOS test-target compilation. The IPA's Bangumi JSON and script exactly match the bundled source, and the 31 JavaScript tests passed. Unzip and sign the IPA, install it, then select Bangumi directly. XCTest was not executed and real-device behavior is not yet verified.
