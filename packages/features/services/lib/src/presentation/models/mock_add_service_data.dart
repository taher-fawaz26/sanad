import 'package:services/src/domain/entities/service_entity.dart';

/// UI-only placeholder data for the Add Service screen.
///
/// The Category and Service Name fields are not yet backed by an API — see
/// the Add Service screen's follow-up task for real category/catalog
/// integration. This file exists purely so the presentation states from the
/// design reference (empty, selected, search, not-found) can be demonstrated.
abstract final class MockAddServiceData {
  MockAddServiceData._();

  /// Placeholder category options for the Category field.
  static const List<String> categories = [
    'Car',
    'Home Maintenance',
    'Home Services',
    'Cleaning',
    'Beauty & Wellness',
  ];

  /// Placeholder catalog for the Service Name field.
  static const List<ServiceEntity> servicesByCategory = [
    ServiceEntity(id: 'svc-wash-car', name: 'Wash Car', category: 'Car'),
    ServiceEntity(id: 'svc-oil-change', name: 'Oil Change', category: 'Car'),
    ServiceEntity(
      id: 'svc-tire-rotation',
      name: 'Tire Rotation',
      category: 'Car',
    ),
    ServiceEntity(
      id: 'svc-ac-repair',
      name: 'AC Repair',
      category: 'Home Maintenance',
    ),
    ServiceEntity(
      id: 'svc-plumbing',
      name: 'Plumbing',
      category: 'Home Services',
    ),
    ServiceEntity(
      id: 'svc-electrical',
      name: 'Electrical',
      category: 'Home Services',
    ),
  ];

  /// Services in [servicesByCategory] belonging to [category].
  static List<ServiceEntity> servicesFor(String category) => servicesByCategory
      .where((service) => service.category == category)
      .toList();
}
