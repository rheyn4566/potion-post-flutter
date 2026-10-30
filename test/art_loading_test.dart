import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potion_post/ui/scene_transition.dart';

Widget scene(
  String id,
  SceneImageLoader loader, {
  bool motion = true,
  bool systemReducedMotion = false,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: systemReducedMotion),
    child: SceneTransition(
      scene: id,
      images: [AssetImage('$id.webp')],
      loadImages: loader,
      animate: motion,
      child: Center(child: Text('Screen $id')),
    ),
  ),
);

void main() {
  testWidgets('Cold launch waits for art before revealing the first screen', (
    tester,
  ) async {
    final loaded = Completer<void>();
    await tester.pumpWidget(scene('home', (_, _) => loaded.future));
    expect(find.text('Screen home'), findsNothing);
    expect(find.text('Preparing your post…'), findsOneWidget);
    loaded.complete();
    await tester.pump();
    expect(find.text('Screen home'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('scene-loading-veil')), findsNothing);
  });

  testWidgets(
    'Switch holds the outgoing scene until incoming artwork is ready',
    (tester) async {
      final next = Completer<void>();
      Future<void> load(BuildContext _, List<ImageProvider> images) =>
          (images.first as AssetImage).assetName == 'daily.webp'
          ? next.future
          : Future.value();
      await tester.pumpWidget(scene('home', load));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(scene('daily', load));
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.text('Screen home'), findsOneWidget);
      expect(find.text('Screen daily'), findsNothing);
      expect(
        tester.widget<AbsorbPointer>(find.byType(AbsorbPointer).last).absorbing,
        isTrue,
      );
      next.complete();
      await tester.pump();
      expect(find.text('Screen daily'), findsOneWidget);
      expect(find.text('Screen home'), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('scene-loading-veil')), findsNothing);
    },
  );

  testWidgets('A late decode cannot replace a newer navigation destination', (
    tester,
  ) async {
    final loads = <String, Completer<void>>{};
    Future<void> load(BuildContext _, List<ImageProvider> images) =>
        (loads[(images.first as AssetImage).assetName] ??= Completer<void>())
            .future;
    await tester.pumpWidget(scene('home', load, motion: false));
    loads['home.webp']!.complete();
    await tester.pump();
    await tester.pumpWidget(scene('daily', load, motion: false));
    await tester.pumpWidget(scene('gardens', load, motion: false));
    loads['gardens.webp']!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Screen gardens'), findsOneWidget);
    loads['daily.webp']!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Screen gardens'), findsOneWidget);
    expect(find.text('Screen daily'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'System Reduce Motion reveals loaded screens without a fade or slide',
    (tester) async {
      final loaded = Completer<void>();
      await tester.pumpWidget(
        scene('home', (_, _) => loaded.future, systemReducedMotion: true),
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
      loaded.complete();
      await tester.pump();
      expect(find.text('Screen home'), findsOneWidget);
      expect(find.byKey(const ValueKey('scene-loading-veil')), findsNothing);
      final transform = tester.widget<Transform>(find.byType(Transform).last);
      expect(transform.transform.getTranslation().y, 0);
    },
  );

  testWidgets(
    'Leaving a scene during decoding does not complete a disposed state',
    (tester) async {
      final loaded = Completer<void>();
      await tester.pumpWidget(scene('home', (_, _) => loaded.future));
      await tester.pumpWidget(const SizedBox.shrink());
      loaded.complete();
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
