import 'package:device/src/domain/services/clipboard_service.dart';
import 'package:device/src/infrastructure/providers/clipboard_provider.dart';

class ClipboardServiceImpl implements ClipboardService {
  const ClipboardServiceImpl(this._provider);

  final ClipboardProvider _provider;

  @override
  Future<void> copy(String text) => _provider.copy(text);

  @override
  Future<String?> paste() => _provider.paste();

  @override
  Future<void> clear() => _provider.clear();

  @override
  Future<bool> hasData() => _provider.hasData();
}
