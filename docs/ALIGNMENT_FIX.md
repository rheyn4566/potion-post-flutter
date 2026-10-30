# Android frame alignment — 0.8.1+18

The uploaded 0.8.0 screenshots showed small left-aligned button skins behind centered labels, progress tracks outside their cream panels, navigation labels drifting past their painted slots and a Pause popup whose panel did not cover its contents.

The shared StoryFrame used an image-provider scale of 4 but supplied centerSlice in physical sprite pixels. Flutter's paintImage multiplies centerSlice by that provider scale, so the resulting source rectangle exceeded the image. The updated renderer converts the slice coordinates into logical image units. The complete painted face now occupies the same bounds as its native Flutter content and touch target.

The navigation atlas has five wells within its first 650 source pixels, followed by unused canvas out to pixel 709. The renderer clips the unused tail and places the five live tabs over the actual wells; every tab retains at least a 48x48 logical-pixel hit area on supported phone layouts.

Daily's background and foreground now share one camera transform, anchored to the counter at source y=942 in the 1122x1402 office illustration. The courier and foreground clip use that same counter position, including when the available scene height changes.

Regression checks validate source bounds and painted coverage for button, panel and dialog at density 2.75. A separate interaction test exercises all five tabs, order 7, Pause/resume and Delivery at 1280x2048 pixels with density 2 and system insets. The uploaded images establish pixel dimensions; the device's actual density was not supplied. Existing responsive tests also cover 320x568, 360x640, 390x844, 844x390 and 758x1216 logical viewports.

The app retains the existing package ID, signing certificate, save schema, original order payloads, currencies, prices, route IDs and all artwork. No new character or garden duplicates were added for this correction. Physical Android testing remains to be done; the current evidence consists of Flutter host renders, automated interactions and native APK verification.
