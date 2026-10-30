# Potion Post 0.10.0 (20) validation

Flutter 3.47.6, Dart 3.13.5, Microsoft JDK 17.0.20.1. The dependency lock and Ads Test signing identity are retained.

- Full suite: 68 automated tests passed (docs/TEST_RESULTS.txt).
- Flutter analysis: no issues (docs/ANALYZE.txt).
- Existing puzzle, pour, reward-once, daily bonus, purchase confirmation/cancellation, route-lock, save-recovery and separate-process persistence checks continue to pass.
- Garden-world regression: selecting a locked garden previews that environment without changing the saved selected look; returning Home restores the selected world. All 43 route IDs resolve to a packaged world environment. All 26 courier IDs have a normalized world pose.
- Grounding: actor bounds fit the clear scene on 320x568, 640x1024, 758x1216, 1024x768 and 844x390 windows. Feet remain aligned with their contact shadows during breathing. Reduce motion stops the pose transform.
- Controls: no decorative flower-cluster widget or flower-ornament asset appears on ordinary hub, shop or puzzle controls. Semantic garden flower icons remain. All five tabs, live order selection, daily tickets, companion invitations and the persistent banner continue to function.
- Tablet capture: all five destinations, Decor shop, gameplay, Pause/resume and Delivery at the uploaded 1280x2048 dimensions with density 2 and system insets. Additional Lily Pond Home/Gardens, Sunpetal preview and landscape captures are included. The physical device's exact density was not supplied.
- Actual Flutter renders await their visible image providers before capture, including resized portraits and newly selected worlds. Current images are docs/ALIGNED_*.png, WORLD_*.png and POLISHED_SHOP.png. These are host widget renders, not photographs of an Android device.
- Scenery: 19 distinct full environment paintings and 26 world-pose exports. Three poses are newly generated; the other 23 reuse existing courier art. Remaining routes use explicitly mapped themed variants. This does not claim 43 unique environment paintings.
- Complete 1,480-order JSON and controller/domain/storage files match the 0.9.0+19 source baseline. Original 1,000 order payloads remain preserved. Details: docs/DATA_COMPATIBILITY.json.
- Release identity, signature, ZIP integrity, all 45 world/pose asset bytes and 16 KB ZIP/native alignment are verified by scripts/verify_apk.py and recorded in docs/APK_BUILD.json after the build.
- No physical Android device or emulator run was performed; device performance and ad-network availability remain unverified.
