import 'dart:io';

import 'package:device/src/domain/entities/device_info_data.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Wraps `device_info_plus`. No plugin type escapes this class.
class DeviceInfoProvider {
  DeviceInfoProvider([DeviceInfoPlugin? plugin])
    : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  Future<DeviceInfoData> getDeviceInfo() async {
    if (Platform.isAndroid) {
      final info = await _plugin.androidInfo;
      return DeviceInfoData(
        model: info.model,
        manufacturer: info.manufacturer,
        brand: info.brand,
        osVersion: info.version.release,
        sdkVersion: info.version.sdkInt.toString(),
        // device_info_plus exposes no reliable Android tablet flag; screen-size
        // based detection belongs to the UI layer, so we conservatively report
        // false here.
        isTablet: false,
        isPhysicalDevice: info.isPhysicalDevice,
        deviceId: info.id,
      );
    }

    if (Platform.isIOS) {
      final info = await _plugin.iosInfo;
      return DeviceInfoData(
        model: info.utsname.machine,
        manufacturer: 'Apple',
        brand: 'Apple',
        osVersion: info.systemVersion,
        sdkVersion: info.systemVersion,
        isTablet: info.model.toLowerCase().contains('ipad'),
        isPhysicalDevice: info.isPhysicalDevice,
        deviceId: info.identifierForVendor,
      );
    }

    // Non-mobile platforms: return a minimal, non-null snapshot.
    return const DeviceInfoData(
      model: '',
      manufacturer: '',
      brand: '',
      osVersion: '',
      sdkVersion: '',
      isTablet: false,
      isPhysicalDevice: true,
    );
  }
}
