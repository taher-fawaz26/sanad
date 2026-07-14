/// Formats a radius in km for display.
///
/// Whole numbers show no decimals (`5`), fractional values show one
/// decimal (`2.5`).
String formatRadiusKm(double radiusKm) =>
    radiusKm.toStringAsFixed(radiusKm % 1 == 0 ? 0 : 1);
