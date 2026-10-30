# Smooth scene loading — 0.10.1+21

The previous build requested decoded artwork as each new screen mounted. This update prepares each destination's critical images before revealing its contents. A 90 ms outgoing veil and 260 ms fade with an 8 logical pixel entrance keep the transition short. The outgoing scene remains mounted while the next scene loads. A cold launch uses a lightweight native postal panel, with a real indeterminate indicator during decoding. No timer invents a completion percentage.

Only one content subtree is mounted at a time. Older asynchronous loads cannot replace a newer navigation request. During viewport changes an outgoing layout is removed if it no longer fits, so rotating during loading cannot briefly overflow the screen. Both app and system Reduce Motion preferences disable the fade and slide. Secondary first-time illustrations fade in for 180 ms; cache hits paint immediately.

ArtImages supplies the same ResizeImage keys to preloading and painting. Backgrounds choose 512, 768 or 1024 decoded pixels across based on the physical short side of the viewport; portraits, world poses, garden thumbnails and the companion dais use a 512-pixel decode width. Original source artwork remains bundled. The standard 100 MiB Flutter image cache is retained. Visible images and a small neighborhood of likely destinations are warmed sequentially, rather than decoding every garden at launch.

The five main tablet tabs were checked from a cleared cache at 1280×2048 with density 2. Every visible RawImage was decoded when the destination was revealed. Decoded cache occupancy was 51,956,388–55,306,916 bytes, about 49.5–52.7 MiB. docs/LOADING_CACHE.json contains the per-tab values. This measures Flutter's host image cache, not total Android process RAM or physical tablet timing.

The full 74-test suite covers cold startup, delayed decoding, superseded navigation, disposal during loading, Reduce Motion, tablet cache occupancy, visible image readiness, rotation, layout, saves, purchases and existing puzzle behavior. The test harness now exercises the production loading path under the normal cache limit instead of precaching all images in a 600 MiB cache.

Implementation: lib/ui/art_cache.dart, lib/ui/scene_transition.dart, the hub and gameplay entry points. Existing controller, domain, persistence and order JSON bytes are unchanged from source version 19; see LOADING_COMPATIBILITY.json.

Flutter references: [precacheImage](https://api.flutter.dev/flutter/widgets/precacheImage.html), [Image decoding and memory](https://api.flutter.dev/flutter/widgets/Image-class.html), [ImageCache](https://api.flutter.dev/flutter/painting/ImageCache-class.html).
