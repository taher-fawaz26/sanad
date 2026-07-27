import 'package:device/src/domain/entities/device_info_data.dart';
import 'package:device/src/domain/services/device_info_service.dart';
import 'package:device/src/infrastructure/providers/device_info_provider.dart';

class DeviceInfoServiceImpl implements DeviceInfoService {
  const DeviceInfoServiceImpl(this._provider);

  final DeviceInfoProvider _provider;

  @override
  Future<DeviceInfoData> getDeviceInfo() => _provider.getDeviceInfo();
}
