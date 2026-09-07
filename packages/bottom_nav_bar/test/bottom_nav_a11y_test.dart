import 'package:bottom_nav_bar/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Dest { home, settings }

enum _Action { services, requests }

Widget _icon(BuildContext context, {required bool selected}) {
  return Icon(Icons.home);
}

Widget _actionIcon(BuildContext context, {required bool selected}) {
  return const Icon(Icons.build);
}

Widget _requestsIcon(BuildContext context, {required bool selected}) {
  return const Icon(Icons.mail);
}

void main() {
  group('BottomNav accessibility', () {
    testWidgets('destination exposes semantics label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomNavBar<_Dest>(
              destinations: const [
                BottomNavDestination(
                  item: _Dest.home,
                  label: 'Home',
                  semanticLabel: 'Home tab',
                  iconBuilder: _icon,
                ),
                BottomNavDestination(
                  item: _Dest.settings,
                  label: 'Settings',
                  iconBuilder: _icon,
                ),
              ],
              selectedItem: _Dest.home,
              theme: const BottomNavThemeData(),
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.text('Home'));
      expect(semantics.label, contains('Home tab'));
    });

    testWidgets('disabled destination is not tappable', (tester) async {
      _Dest? tapped;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomNavBar<_Dest>(
              destinations: const [
                BottomNavDestination(
                  item: _Dest.home,
                  label: 'Home',
                  iconBuilder: _icon,
                  enabled: false,
                ),
                BottomNavDestination(
                  item: _Dest.settings,
                  label: 'Settings',
                  iconBuilder: _icon,
                ),
              ],
              selectedItem: _Dest.settings,
              theme: const BottomNavThemeData(),
              onDestinationSelected: (item) => tapped = item,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(tapped, isNull);
    });

    testWidgets('dark theme colors resolve from BottomNavThemeData', (
      tester,
    ) async {
      const darkTheme = BottomNavThemeData(
        barColor: Color(0xFF111111),
        selectedColor: Color(0xFF00FF00),
        unselectedColor: Color(0xFF888888),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            bottomNavigationBar: BottomNavBar<_Dest>(
              destinations: const [
                BottomNavDestination(
                  item: _Dest.home,
                  label: 'Home',
                  iconBuilder: _icon,
                ),
                BottomNavDestination(
                  item: _Dest.settings,
                  label: 'Settings',
                  iconBuilder: _icon,
                ),
              ],
              selectedItem: _Dest.home,
              theme: darkTheme,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(BottomNavBar<_Dest>), findsOneWidget);
    });

    testWidgets('center action exposes semantics', (tester) async {
      final controller = BottomNavController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButtonLocation: BottomNavExpandableCenter.fabLocation,
            floatingActionButton: BottomNavExpandableCenter<_Action>(
              actions: const [
                BottomNavAction(
                  item: _Action.services,
                  label: 'Services',
                  semanticLabel: 'Open services',
                  iconBuilder: _actionIcon,
                ),
                BottomNavAction(
                  item: _Action.requests,
                  label: 'Requests',
                  semanticLabel: 'Open requests',
                  iconBuilder: _requestsIcon,
                ),
              ],
              selectedItem: null,
              controller: controller,
              theme: const BottomNavThemeData(),
              onActionSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Open services'), findsOneWidget);
    });
  });
}
