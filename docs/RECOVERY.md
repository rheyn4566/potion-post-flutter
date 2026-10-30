# Source recovery for 0.6.3

The retrieved 0.6.2 archive contained 402 complete local ZIP entries, then ended
inside the archived browser preview. It had no central directory and omitted
later package manifest, test-signing, test, authoring-tool and web-runner files.
Each complete recovered entry was inflated and checked against its length and
CRC before extraction. Current Dart game code, all 1,000 orders, artwork/fonts,
Android/iOS runners, docs and the 0.6.2 compact layout recovered intact.

Missing package/build files and relevant tests were recreated. The archived
browser preview remains a separate older artifact and is not needed by Flutter.
The original private test key could not be recovered. The included new
`potion-post-ads-test.jks` signs `com.castilla.potion_post.adtest` only, preserving
the existing installed game. Standard-release builds require the original key
and cannot silently fall back to this new one. Existing version-one saves can
be copied through the original Copy progress/Restore progress settings.

Historical validations describe earlier builds. Current evidence is in
`VALIDATION.md` and `docs/APK_BUILD.json`.
