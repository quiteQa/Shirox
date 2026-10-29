# Bangumi metadata modules

This change adds type: metadata modules to Home, Search and title details, separately from playback.

Use a build with this patch, then import https://raw.githubusercontent.com/quiteQa/shirox-bangumi/main/bangumi.json . Refresh an older installed module to version 0.3.0 and run Check Again. Metadata health checks call searchMetadata and extractMetadata, never video streams.

Select Bangumi in Modules or the Home source menu. Home displays score ranking and premiere-date catalogs. Title details display native metadata and can be saved to the local library. Find a playback source searches installed website modules; the user confirms the matching title. Playback and downloads remain on that website module.

Bangumi IDs remain in a namespaced identity and are not sent as AniList/MAL IDs. Metadata reading uses a separate JS runner. New settings participate in backups and profile switching.

The contract consists of searchMetadata(keyword), extractMetadata(subjectID), extractEpisodeMetadata(subjectID), and browseMetadata(topRated or newest, page), returning JSON strings documented in the module repository.

MetadataModuleTests covers classification, score conversion, namespaced IDs, persistence, routing, and health checks that must not request a stream. New files are registered for iOS, macOS, tvOS and the iOS test target; Catalyst uses the iOS target. UI strings cover all 13 languages.

## Verified source and builds

This fork applies the same native source change as the verified patch in [quiteQa/shirox-bangumi](https://github.com/quiteQa/shirox-bangumi/blob/4c8be565a3ee2b67ebec76cd1812f202c3e272d2/native/shirox-metadata.patch), on upstream commit `398d36715b34a17ec68bfd52d792f7a2e7db06f5`.

[Build run 40844088237](https://github.com/quiteQa/shirox-bangumi/actions/runs/40844088237) passed all four app builds: iOS, macOS, tvOS and Mac Catalyst. The iOS test target also compiled successfully for the arm64 iOS Simulator. XCTest was not executed, no simulator was booted, and real-device behavior has not been verified. Existing libzstd module-import and AppIntents metadata warnings remain.

The module's 31 offline JavaScript tests, localization and icon checks passed. [Strict SwiftLint](https://github.com/quiteQa/shirox-bangumi/actions/runs/40844088197) also passed. A small upstream test expression in `TSAudioTimestampsTests` was split into intermediate values to avoid a compiler type-check timeout without changing the test's behavior.

## Install on iPhone or iPad

1. [Download the verified iOS artifact](https://github.com/quiteQa/shirox-bangumi/actions/runs/40844088237/artifacts/12883669458), unzip it and sign `Shirox-metadata-unsigned.ipa` with your own sideloading method. This is an unsigned development build.
2. Import or refresh the module JSON URL above to version **0.3.0**.
3. Select Bangumi in Modules or the Home source menu. Re-run the module check if an old stream error remains.

Bangumi provides metadata. To watch a title, use the detail page's playback-source picker and select a matching title from an installed playback module.

The upstream installation links elsewhere in the README point to the official app, which does not include this native metadata integration. GitHub Actions artifacts require a GitHub login to download and are subject to retention expiry.
