import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the branch location in the device maps app.
abstract final class BranchMapsLauncher {
  BranchMapsLauncher._();

  static Future<bool> openBranchLocation(BranchEntity branch) async {
    final uri = _resolveUri(branch);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Opens raw coordinates in the device maps app. Used by the add-branch
  /// review screen, where no saved [BranchEntity] exists yet.
  static Future<bool> openCoordinates(double lat, double lng) {
    return launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
      mode: LaunchMode.externalApplication,
    );
  }

  static Uri? _resolveUri(BranchEntity branch) {
    final googleMapsLink = branch.googleMapsLink?.trim();
    if (googleMapsLink != null && googleMapsLink.isNotEmpty) {
      return Uri.tryParse(googleMapsLink);
    }

    final lat = branch.lat;
    final lng = branch.lng;
    if (lat != null && lng != null) {
      return Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    }

    final query = Uri.encodeComponent(branch.displayAddress);
    if (query.isEmpty) return null;
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
  }
}
