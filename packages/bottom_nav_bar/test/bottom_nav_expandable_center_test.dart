import 'package:bottom_nav_bar/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Action { services, requests, messages }

Widget _actionIcon(BuildContext context, {required bool selected}) {
  return Icon(Icons.work, color: selected ? Colors.white : Colors.grey);
}

Widget _requestsIcon(BuildContext context, {required bool selected}) {
  return Icon(Icons.request_page, color: selected ? Colors.white : Colors.grey);
}

Widget _messagesIcon(BuildContext context, {required bool selected}) {
  return Icon(Icons.message, color: selected ? Colors.white : Colors.grey);
}

void main() {
  group('BottomNavExpandableCenter', () {
    testWidgets('shows plus when permanent tab selected', (tester) async {
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
                  iconBuilder: _actionIcon,
                ),
                BottomNavAction(
                  item: _Action.requests,
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

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows action icon when action selected', (tester) async {
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
                  iconBuilder: _actionIcon,
                ),
                BottomNavAction(
                  item: _Action.requests,
                  iconBuilder: _requestsIcon,
                ),
              ],
              selectedItem: _Action.services,
              controller: controller,
              theme: const BottomNavThemeData(),
              onActionSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.work), findsWidgets);
    });

    testWidgets('custom fabBuilder replaces default face', (tester) async {
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
                  iconBuilder: _actionIcon,
                ),
                BottomNavAction(
                  item: _Action.requests,
                  iconBuilder: _requestsIcon,
                ),
              ],
              selectedItem: null,
              controller: controller,
              theme: const BottomNavThemeData(),
              onActionSelected: (_) {},
              fabBuilder:
                  (
                    context, {
                    required selectedItem,
                    required isExpanded,
                    required onPressed,
                    required theme,
                    required actions,
                  }) {
                    return const Text('Custom');
                  },
            ),
          ),
        ),
      );

      expect(find.text('Custom'), findsNWidgets(2));
    });

    testWidgets('fabLocation is non-null', (tester) async {
      expect(BottomNavExpandableCenter.fabLocation, isNotNull);
    });

    testWidgets('center fan action receives tap when menu expanded', (
      tester,
    ) async {
      _Action? selected;
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
                  iconBuilder: _actionIcon,
                ),
                BottomNavAction(
                  item: _Action.requests,
                  iconBuilder: _requestsIcon,
                ),
                BottomNavAction(
                  item: _Action.messages,
                  iconBuilder: _messagesIcon,
                ),
              ],
              selectedItem: null,
              controller: controller,
              theme: const BottomNavThemeData(),
              onActionSelected: (item) => selected = item,
            ),
          ),
        ),
      );

      controller.expand();
      await tester.pumpAndSettle();

      final requestsIcon = find.byIcon(Icons.request_page);
      final iconBox = tester.getRect(requestsIcon);
      await tester.tapAt(iconBox.center);
      await tester.pumpAndSettle();

      expect(selected, _Action.requests);
    });
  });
}
