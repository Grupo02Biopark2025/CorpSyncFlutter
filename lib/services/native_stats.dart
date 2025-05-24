import 'package:flutter/services.dart';
import 'dart:io';

class NativeStatsService {
  static const platform = MethodChannel('com.berna.corp_syncmdm/native_stats');

  // Informações de disco
  static Future<Map<String, dynamic>> getDiskSpace() async {
    if (!Platform.isAndroid) {
      return {
        'total_disk_space': '32.0GB',
        'free_disk_space': '16.0GB',
        'disk_used_percentage': '50.0',
      };
    }

    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod('getDiskSpace');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      print("Error getting disk space: ${e.message}");
      return {
        'error': e.message,
        'total_disk_space': '0GB',
        'free_disk_space': '0GB',
        'disk_used_percentage': '0',
      };
    }
  }

  // Verificar permissão de estatísticas de uso
  static Future<bool> hasUsageStatsPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final bool hasPermission = await platform.invokeMethod('hasUsageStatsPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      print("Error checking usage stats permission: ${e.message}");
      return false;
    }
  }

  // Solicitar permissão de estatísticas de uso
  static Future<void> requestUsageStatsPermission() async {
    if (!Platform.isAndroid) return;

    try {
      await platform.invokeMethod('requestUsageStatsPermission');
    } on PlatformException catch (e) {
      print("Error requesting usage stats permission: ${e.message}");
    }
  }

  // Obter estatísticas de uso de aplicativos
  static Future<Map<String, dynamic>> getAppUsageStats() async {
    if (!Platform.isAndroid) {
      return {
        'total_screen_time_minutes': 0,
        'screen_time_hours': '0.0',
        'top_apps': {},
      };
    }

    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod('getAppUsageStats');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      print("Error getting app usage stats: ${e.message}");
      return {
        'error': e.message,
        'total_screen_time_minutes': 0,
        'top_apps': {},
      };
    }
  }

  // Obter informações de aplicativos instalados
  static Future<Map<String, dynamic>> getInstalledAppsInfo() async {
    if (!Platform.isAndroid) {
      return {
        'total_apps_count': 0,
        'system_apps_count': 0,
        'user_apps_count': 0,
      };
    }

    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod('getInstalledAppsCount');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      print("Error getting installed apps info: ${e.message}");
      return {
        'error': e.message,
        'total_apps_count': 0,
        'system_apps_count': 0,
        'user_apps_count': 0,
      };
    }
  }
}