import 'package:bottom_nav_bar/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Dest { home, settings }

Widget _icon(BuildContext context, {required bool selected}) {
  return Icon(selected ? Icons.home : Icons.home_outlined);
}

void main() {
  group('BottomNavBar', () {
    testWidgets('invokes callback with destination item', (tester) async {
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
                ),
                BottomNavDestination(
                  item: _Dest.settings,
                  label: 'Settings',
                  iconBuilder: _icon,
                ),
              ],
              selectedItem: _Dest.home,
              theme: const BottomNavThemeData(),
              onDestinationSelected: (item) => tapped = item,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(tapped, _Dest.settings);
    });

    testWidgets('renders in RTL', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
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
                theme: const BottomNavThemeData(),
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders custom painted notch bar when centerGap > 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButtonLocation:
                BottomNavExpandableCenter.fabLocation,
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
              theme: const BottomNavThemeData(),
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(BottomNavBar<_Dest>),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders flat bar without notch when centerGap is 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
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
              theme: const BottomNavThemeData(centerGap: 0),
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(BottomNavBar<_Dest>),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
      expect(find.byType(DecoratedBox), findsWidgets);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('respects large text scale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
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
                theme: const BottomNavThemeData(),
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('lifts bar above Android system navigation inset', (
      tester,
    ) async {
      const systemBottom = 48.0;
      const theme = BottomNavThemeData(bottomInset: 8);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              // Edge-to-edge Android: padding.bottom is 0, viewPadding holds
              // the system navigation bar height.
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.only(bottom: systemBottom),
            ),
            child: const Scaffold(
              bottomNavigationBar: BottomNavBar<_Dest>(
                destinations: [
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
                theme: theme,
                onDestinationSelected: _noop,
              ),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(BottomNavBar<_Dest>),
              matching: find.byType(Padding),
            )
            .first,
      );

      expect(
        padding.padding,
        EdgeInsets.fromLTRB(
          theme.horizontalInset,
          0,
          theme.horizontalInset,
          theme.bottomInset + systemBottom,
        ),
      );
    });
  });
}

void _noop(_Dest _) {}
