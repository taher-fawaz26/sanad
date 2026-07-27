import 'package:device/src/domain/entities/app_info_data.dart';
import 'package:device/src/domain/services/app_info_service.dart';
import 'package:device/src/infrastructure/providers/app_info_provider.dart';

class AppInfoServiceImpl implements AppInfoService {
  const AppInfoServiceImpl(this._provider);

  final AppInfoProvider _provider;

  @override
  Future<AppInfoData> getAppInfo() => _provider.getAppInfo();
}
