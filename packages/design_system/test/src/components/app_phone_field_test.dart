import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Reproduces the crash pattern from a real caller (branches'
/// `ContactEditSheet`): a parent owns the [TextEditingController], listens on
/// it with a synchronous `setState`, and mounts [AppPhoneField] with it
/// during the parent's own first build.
class _ParentWithControllerListener extends StatefulWidget {
  const _ParentWithControllerListener({required this.initialPhone});

  final String initialPhone;

  @override
  State<_ParentWithControllerListener> createState() =>
      _ParentWithControllerListenerState();
}

class _ParentWithControllerListenerState
    extends State<_ParentWithControllerListener> {
  late final _controller = TextEditingController(text: widget.initialPhone);

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPhoneField(label: 'Phone', controller: _controller);
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection ambient = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Directionality(
          textDirection: ambient,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
}

bool _isFlagAsset(Widget widget) {
  if (widget is! SvgPicture) return false;
  final loader = widget.bytesLoader;
  return loader is SvgAssetLoader && loader.assetName == AppSvgs.flagAe;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('AppPhoneField dial-code stripping', () {
    testWidgets(
      'does not re-enter a still-building parent that listens on the '
      "controller (regression: framework's !_dirty assertion)",
      (tester) async {
        // `971501234567` needs stripping to `501234567` — this is the case
        // that used to mutate the controller synchronously in initState and
        // crash when a parent's listener called setState mid-build.
        await _pump(
          tester,
          const _ParentWithControllerListener(initialPhone: '971501234567'),
        );

        expect(tester.takeException(), isNull);

        // The strip is now deferred to a post-frame callback.
        await tester.pump();

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.controller!.text, '501234567');
      },
    );

    testWidgets('leaves an already-national value untouched', (tester) async {
      await _pump(
        tester,
        const _ParentWithControllerListener(initialPhone: '501234567'),
      );
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '501234567');
      expect(tester.takeException(), isNull);
    });
  });

  group('AppPhoneField trailing action', () {
    testWidgets(
      'does not starve the digits of width at a realistic phone width '
      '(regression: Align with no widthFactor tried to fill all available '
      'width, leaving 0px for the value — reported as "empty" fields even '
      'though the correct value was present in the tree)',
      (tester) async {
        await _pump(
          tester,
          AppPhoneField(
            label: 'Phone',
            controller: TextEditingController(text: '501234567'),
            readOnly: true,
            trailing: const AppFieldTextLinkTrailing(label: 'Change'),
          ),
        );

        final finder = find.text('501234567');
        expect(finder, findsOneWidget);
        expect(tester.getSize(finder).width, greaterThan(0));
      },
    );
  });

  group('AppPhoneField validator', () {
    testWidgets('shows the validator message when validation fails', (
      tester,
    ) async {
      await _pump(
        tester,
        Form(
          child: AppPhoneField(
            label: 'Phone',
            controller: TextEditingController(text: ''),
            autovalidateMode: AutovalidateMode.always,
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Invalid phone' : null,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Invalid phone'), findsOneWidget);
    });

    testWidgets('shows no error when the validator passes', (tester) async {
      await _pump(
        tester,
        Form(
          child: AppPhoneField(
            label: 'Phone',
            controller: TextEditingController(text: '501234567'),
            autovalidateMode: AutovalidateMode.always,
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Invalid phone' : null,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Invalid phone'), findsNothing);
    });

    testWidgets('an explicit errorText overrides the validator result', (
      tester,
    ) async {
      await _pump(
        tester,
        Form(
          child: AppPhoneField(
            label: 'Phone',
            controller: TextEditingController(text: '501234567'),
            autovalidateMode: AutovalidateMode.always,
            errorText: 'Server says invalid',
            validator: (value) => null,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Server says invalid'), findsOneWidget);
    });

    testWidgets('Form.validate() triggers the validator and surfaces its '
        'message', (tester) async {
      final formKey = GlobalKey<FormState>();
      await _pump(
        tester,
        Form(
          key: formKey,
          child: AppPhoneField(
            label: 'Phone',
            controller: TextEditingController(text: ''),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Required' : null,
          ),
        ),
      );
      await tester.pump();

      final isValid = formKey.currentState!.validate();
      await tester.pump();

      expect(isValid, isFalse);
      expect(find.text('Required'), findsOneWidget);
    });
  });

  group('AppPhoneField direction', () {
    testWidgets('forces the input row to LTR under an RTL ambient (Arabic)', (
      tester,
    ) async {
      await _pump(
        tester,
        AppPhoneField(
          label: 'رقم الهاتف',
          controller: TextEditingController(text: '501234567'),
        ),
        ambient: TextDirection.rtl,
      );

      expect(
        Directionality.of(tester.element(find.byType(TextField))),
        TextDirection.ltr,
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textDirection, TextDirection.ltr);
    });

    testWidgets('keeps the input row LTR under an LTR ambient (English)', (
      tester,
    ) async {
      await _pump(
        tester,
        AppPhoneField(
          label: 'Phone number',
          controller: TextEditingController(text: '501234567'),
        ),
      );

      expect(
        Directionality.of(tester.element(find.byType(TextField))),
        TextDirection.ltr,
      );
    });

    testWidgets(
      'flag + dial code sit on the visual left of the input under RTL',
      (tester) async {
        await _pump(
          tester,
          AppPhoneField(
            label: 'رقم الهاتف',
            controller: TextEditingController(text: '501234567'),
          ),
          ambient: TextDirection.rtl,
        );

        final dialCodeCenter = tester.getCenter(find.text('+971'));
        final fieldCenter = tester.getCenter(find.byType(TextField));
        expect(
          dialCodeCenter.dx,
          lessThan(fieldCenter.dx),
          reason:
              'Phone field is inherently LTR: the flag and +971 prefix must '
              'always sit on the visual left, even under an RTL locale.',
        );
      },
    );
  });

  group('AppPhoneField skeleton', () {
    testWidgets(
      'hides the real country flag while an enabled Skeletonizer is active',
      (tester) async {
        await _pump(
          tester,
          Skeletonizer(
            child: AppPhoneField(
              label: 'Phone',
              controller: TextEditingController(text: '501234567'),
            ),
          ),
        );
        // The shimmer animation repeats indefinitely — pump bounded frames
        // instead of pumpAndSettle(), which would never return.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byWidgetPredicate(_isFlagAsset), findsNothing);
      },
    );

    testWidgets('shows the real country flag when not skeletonized', (
      tester,
    ) async {
      await _pump(
        tester,
        AppPhoneField(
          label: 'Phone',
          controller: TextEditingController(text: '501234567'),
        ),
      );

      expect(find.byWidgetPredicate(_isFlagAsset), findsOneWidget);
    });

    testWidgets(
      'shows the real country flag again once Skeletonizer is disabled',
      (tester) async {
        final controller = TextEditingController(text: '501234567');

        await _pump(
          tester,
          Skeletonizer(
            child: AppPhoneField(label: 'Phone', controller: controller),
          ),
        );
        await tester.pump();
        expect(find.byWidgetPredicate(_isFlagAsset), findsNothing);

        await _pump(
          tester,
          Skeletonizer(
            enabled: false,
            child: AppPhoneField(label: 'Phone', controller: controller),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byWidgetPredicate(_isFlagAsset), findsOneWidget);
      },
    );
  });
}
