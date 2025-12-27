import 'dynamic_app_icon_platform_interface.dart';

class DynamicAppIcon {
  Future<String?> getPlatformVersion() {
    return DynamicAppIconPlatform.instance.getPlatformVersion();
  }

  static Future<void> setIcon({
    required String iconName,
    List<String>? aliases,
    String? packageName,
  }) {
    return DynamicAppIconPlatform.instance.setIcon(
      iconName: iconName,
      aliases: aliases,
      packageName: packageName,
    );
  }
}
