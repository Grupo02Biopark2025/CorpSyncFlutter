import 'dart:io';

import 'package:corp_syncmdm/services/native_stats.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:corp_syncmdm/services/api_sync_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

const String periodicSyncTaskName = 'periodicSync';
const String syncTaskType = 'syncTask';
const uuid = Uuid();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    print("Background task started: $taskName");

    try {
      if (taskName == syncTaskType) {
        await performSyncTask();
      }

      return Future.value(true);
    } catch (e) {
      print("Error in background task: $e");
      return Future.value(false);
    }
  });
}

Future<void> initializeWorkManager() async {
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );
  print("Workmanager initialized");
}

Future<void> startPeriodicSyncAfterQRScan() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool("ativar_sync", true);

  await Workmanager().cancelByUniqueName(periodicSyncTaskName);

  await performSyncTask();

  await Workmanager().registerPeriodicTask(
    periodicSyncTaskName,
    syncTaskType,
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(seconds: 5),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  print("Periodic sync task scheduled");
}

Future<void> stopPeriodicSync() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool("ativar_sync", false);
  await Workmanager().cancelByUniqueName(periodicSyncTaskName);
  print("Periodic sync task cancelled");
}

Future<void> performSyncTask() async {
  print("Performing sync task...");

  try {
    Firebase.app();
  } catch (e) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBzjfp1r1Qh1KigA-UfYzrv5IYJ-ha_730",
        appId: "1:159705809298:android:e0f5535f0ca7ed497f814b",
        messagingSenderId: "159705809298",
        projectId: "corpsync-874ab",
      ),
    );
  }

  final prefs = await SharedPreferences.getInstance();
  bool ativarSync = prefs.getBool("ativar_sync") ?? false;

  if (!ativarSync) {
    print("Sync not authorized. QR not scanned yet.");
    return;
  }

  try {
    await saveToFirestore();
    print("Sync task completed successfully");
  } catch (e) {
    print("Failed to sync data to Firestore: $e");
  }
}

// Function to save data to Firestore
Future<void> saveToFirestore() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final prefs = await SharedPreferences.getInstance();
  final String deviceId = prefs.getString('device_id') ?? uuid.v4();

  if (prefs.getString('device_id') == null) {
    await prefs.setString('device_id', deviceId);
  }

  final deviceInfo = await getDeviceInfo();

  await firestore.collection('devices').doc(deviceId).set({
    'message': 'Device sync at ${DateTime.now().toIso8601String()}',
    'timestamp': FieldValue.serverTimestamp(),
    'os': deviceInfo['os'],
    'os_version': deviceInfo['os_version'],
    'model': deviceInfo['model'],
    'manufacturer': deviceInfo['manufacturer'],
    'brand': deviceInfo['brand'],
    'battery_level': deviceInfo['battery_level'],
    'battery_state': deviceInfo['battery_state'],
    'free_disk_space': deviceInfo['free_disk_space'],
    'total_disk_space': deviceInfo['total_disk_space'],
    'disk_used_percentage': deviceInfo['disk_used_percentage'],
    'device_id': deviceId,
    'sync_count': deviceInfo['sync_count'],
    'latitude': deviceInfo['latitude'],
    'longitude': deviceInfo['longitude'],
    'connection_type': deviceInfo['connection_type'],
    'is_online': deviceInfo['is_online'],
    'screen_time_minutes': deviceInfo['screen_time_minutes'],
    'total_apps_count': deviceInfo['total_apps_count'],
    'system_apps_count': deviceInfo['system_apps_count'],
    'user_apps_count': deviceInfo['user_apps_count'],
  }, SetOptions(merge: true));

  // Send data to your backend API
  bool success = await ApiSyncService.sendDeviceInfo(deviceInfo);
  if (!success) {
    await ApiSyncService.queueFailedApiCall(deviceInfo);
  }

  print("Data saved to Firestore with document ID: $deviceId");
}

// Função atualizada para coletar informações do dispositivo
Future<Map<String, dynamic>> getDeviceInfo() async {
  final prefs = await SharedPreferences.getInstance();
  final String deviceId = prefs.getString('device_id') ?? uuid.v4();

  if (prefs.getString('device_id') == null) {
    await prefs.setString('device_id', deviceId);
  }

  // Incrementar contador de sincronização
  final int syncCount = (prefs.getInt('sync_count') ?? 0) + 1;
  await prefs.setInt('sync_count', syncCount);

  // Salvar primeira sincronização se não existir
  if (prefs.getString('first_sync') == null) {
    await prefs.setString('first_sync', DateTime.now().toIso8601String());
  }

  final deviceInfoPlugin = DeviceInfoPlugin();
  final battery = Battery();

  Map<String, dynamic> deviceInfo = {
    'device_id': deviceId,
    'sync_count': syncCount,
    'first_sync': prefs.getString('first_sync') ?? DateTime.now().toIso8601String(),
    'last_sync': DateTime.now().toIso8601String(),
  };

  // Informações básicas do dispositivo
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfoPlugin.androidInfo;
    deviceInfo.addAll({
      'model': androidInfo.model ?? 'Unknown',
      'manufacturer': androidInfo.manufacturer ?? 'Unknown',
      'brand': androidInfo.brand ?? 'Unknown',
      'os': 'Android',
      'os_version': androidInfo.version.release ?? 'Unknown',
      'sdk_version': androidInfo.version.sdkInt.toString(),
      'is_physical_device': androidInfo.isPhysicalDevice,
    });
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfoPlugin.iosInfo;
    deviceInfo.addAll({
      'model': iosInfo.utsname.machine ?? 'Unknown',
      'manufacturer': 'Apple',
      'brand': 'Apple',
      'os': 'iOS',
      'os_version': iosInfo.systemVersion ?? 'Unknown',
      'is_physical_device': iosInfo.isPhysicalDevice,
    });
  }

  // Informações de bateria
  try {
    final batteryLevel = await battery.batteryLevel;
    final batteryState = await battery.batteryState;

    deviceInfo.addAll({
      'battery_level': batteryLevel,
      'battery_state': batteryState.toString(),
    });
  } catch (e) {
    print("Erro ao obter informações de bateria: $e");
  }

  // Informações de armazenamento usando nosso serviço nativo
  try {
    final diskInfo = await NativeStatsService.getDiskSpace();
    deviceInfo.addAll({
      'free_disk_space': diskInfo['free_disk_space'],
      'total_disk_space': diskInfo['total_disk_space'],
      'disk_used_percentage': diskInfo['disk_used_percentage'],
    });
  } catch (e) {
    print("Erro ao obter informações de armazenamento: $e");
    // Fallback para valores padrão
    deviceInfo.addAll({
      'free_disk_space': '16.0GB',
      'total_disk_space': '32.0GB',
      'disk_used_percentage': '50.0',
    });
  }

  // Informações de localização
  try {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      deviceInfo.addAll({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'altitude': position.altitude,
        'location_accuracy': position.accuracy,
        'speed': position.speed,
      });
    } else {
      deviceInfo.addAll({
        'latitude': 0.0,
        'longitude': 0.0,
        'location_error': 'Permissão de localização não concedida',
      });
    }
  } catch (e) {
    deviceInfo.addAll({
      'latitude': 0.0,
      'longitude': 0.0,
      'location_error': 'Erro ao obter localização: $e',
    });
    print("Erro ao obter localização: $e");
  }

  // Informações de conectividade
  try {
    final connectivity = await Connectivity().checkConnectivity();

    String connectionType = 'none';
    switch (connectivity) {
      case ConnectivityResult.wifi:
        connectionType = 'wifi';
        break;
      case ConnectivityResult.mobile:
        connectionType = 'mobile';
        break;
      default:
        connectionType = 'none';
    }

    deviceInfo.addAll({
      'connection_type': connectionType,
      'is_online': connectionType != 'none',
    });
  } catch (e) {
    print("Erro ao obter informações de conectividade: $e");
  }

  // Informações de uso de aplicativos usando nosso serviço nativo
  if (Platform.isAndroid) {
    try {
      bool hasPermission = await NativeStatsService.hasUsageStatsPermission();
      if (hasPermission) {
        final usageStats = await NativeStatsService.getAppUsageStats();
        if (!usageStats.containsKey('error')) {
          deviceInfo['screen_time_minutes'] = usageStats['total_screen_time_minutes'];
          deviceInfo['screen_time_hours'] = usageStats['screen_time_hours'];
          deviceInfo['top_apps'] = usageStats['top_apps'];
        }
      } else {
        // Se não tem permissão, usar valores padrão
        deviceInfo['screen_time_minutes'] = 0;
        deviceInfo['screen_time_hours'] = '0.0';
        deviceInfo['top_apps'] = {};
      }

      // Informações de aplicativos instalados
      final appsInfo = await NativeStatsService.getInstalledAppsInfo();
      if (!appsInfo.containsKey('error')) {
        deviceInfo['total_apps_count'] = appsInfo['total_apps_count'];
        deviceInfo['system_apps_count'] = appsInfo['system_apps_count'];
        deviceInfo['user_apps_count'] = appsInfo['user_apps_count'];
      }
    } catch (e) {
      print("Erro ao obter estatísticas de uso: $e");
      // Valores padrão em caso de erro
      deviceInfo['screen_time_minutes'] = 0;
      deviceInfo['total_apps_count'] = 0;
      deviceInfo['system_apps_count'] = 0;
      deviceInfo['user_apps_count'] = 0;
    }
  } else {
    // Para iOS, usar valores padrão por enquanto
    deviceInfo['screen_time_minutes'] = 0;
    deviceInfo['total_apps_count'] = 0;
    deviceInfo['system_apps_count'] = 0;
    deviceInfo['user_apps_count'] = 0;
  }

  return deviceInfo;
}