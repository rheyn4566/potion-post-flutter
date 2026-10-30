# Validation: Potion Post 0.12.0+23

The Flutter analyzer reports no issues. All 83 tests pass (docs/ANALYZE.txt and docs/TEST_RESULTS.txt), including all previous regressions and four added camera, selection/restart, stone route layout and ornament visibility checks.

The new integration flow uses the actual app and local progress store: purchased hedgehog and Lily Pond decorations are previewed, garden choice is changed through the shop, owned companions are reselected without spending, Home/Gardens/Orders display the saved animal, a locked level stays disabled, and the unlocked order opens correctly. A new controller reads the saved file state and retains the companion, garden, decoration, balance and story frontier. Separate existing tests cover confirmed/cancelled purchases, insufficient funds, once-only ad grants, daily reward limits, save failures and a progress round trip through separate Dart processes.

Map hit targets fit 320×568, 640×1024 and 844×390 layouts. Ornaments stay inside the clear scene at phone/tablet/landscape and a 500×180 shop preview. The home environment decodes to its native 1024-pixel source width instead of a thumbnail. The new camera avoids extra stage-dependent magnification. Existing cold-tablet tests retain an under-80 MiB decoded-art cache working set.

Actual Flutter host renders of the new map, selected garden/animal, and shop were visually inspected. docs/STONE_*.png are interface test renders with simulated banner geometry; they are not Android device captures or proof of live ad serving.

The controller, domain, persistence, all 1,480 order payloads, lockfile, native save bridge and update keystore are byte-identical to source version 22 (docs/SELECTION_COMPATIBILITY.json). Saves require no new migration and purchases do not unlock story levels.

The signed Android package is checked using scripts/verify_apk.py: package/version, Potion Post label, existing update certificate, ZIP CRCs, 16 KiB ZIP/native alignment and bundled artwork. docs/APK_BUILD.json and docs/INSTALLER_BUILD.json record the exact APK and byte-identical installer ZIP after verification completes.

No physical Android device or emulator was available. Ads use Google's demo IDs. Publisher IDs, account consent messages plus the live UMP gating/privacy-options flow, production signing/Play declarations and on-device/internal-track testing remain necessary for publishing. Cash coin packs/Play Billing are not integrated or offered.
