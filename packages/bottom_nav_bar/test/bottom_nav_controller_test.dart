import 'package:bottom_nav_bar/bottom_nav_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BottomNavController', () {
    test('starts collapsed', () {
      final controller = BottomNavController();
      addTearDown(controller.dispose);

      expect(controller.expanded, isFalse);
      expect(controller.isExpanded.value, isFalse);
    });

    test('expand collapse toggle are safe without bound adapter', () {
      final controller = BottomNavController();
      addTearDown(controller.dispose);

      controller.expand();
      controller.collapse();
      controller.toggle();

      expect(controller.expanded, isFalse);
    });

    test('dispose releases listenable', () {
      final controller = BottomNavController();
      controller.dispose();
      expect(controller.isExpanded.value, isFalse);
    });
  });
}
