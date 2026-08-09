/// UI model for a provider service card on the services dashboard.
///
/// Temporary presentation-only shape until the services API returns
/// cover, status, and metrics fields.
class ProviderServiceCardData {
  const ProviderServiceCardData({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.statusLabel,
    required this.requestsCount,
    required this.revenueLabel,
    this.coverAssetPath,
    this.showMoreAction = true,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final String statusLabel;
  final String requestsCount;
  final String revenueLabel;
  final String? coverAssetPath;
  final bool showMoreAction;
}
