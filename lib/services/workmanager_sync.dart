import 'dart:io';

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
    'battery_level': deviceInfo['battery_level'],
    'battery_state': deviceInfo['battery_state'],
    'free_disk_space': deviceInfo['free_disk_space'],
    'total_disk_space': deviceInfo['total_disk_space'],
    'device_id': deviceId,
    'sync_count': deviceInfo['sync_count'],
    'latitude': deviceInfo['latitude'],
    'longitude': deviceInfo['longitude'],
  }, SetOptions(merge: true));


  // Final body for API request
  final body = {
    'message': 'Device sync at ${DateTime.now().toIso8601String()}',
    'timestamp': DateTime.now().toIso8601String(),
    'os': deviceInfo['os'],
    'os_version': deviceInfo['os_version'],
    'model': deviceInfo['model'],
    'battery_level': deviceInfo['battery_level'],
    'battery_state': deviceInfo['battery_state'],
    'free_disk_space': deviceInfo['free_disk_space'],
    'total_disk_space': deviceInfo['total_disk_space'],
    'device_id': deviceInfo['device_id'],
    'sync_count': deviceInfo['sync_count'],
    'latitude': deviceInfo['latitude'],
    'longitude': deviceInfo['longitude'],
  };

  // Send data to your backend API
  bool success = await ApiSyncService.sendDeviceInfo(deviceInfo);
  if (!success) {
    await ApiSyncService.queueFailedApiCall(deviceInfo);
  }


  print("Data saved to Firestore with document ID: $deviceId");
}

// Optional: Gather some device information
Future<Map<String, dynamic>> getDeviceInfo() async {
  final prefs = await SharedPreferences.getInstance();
  final String deviceId = prefs.getString('device_id') ?? uuid.v4();



  if (prefs.getString('device_id') == null) {
    await prefs.setString('device_id', deviceId);
  }

  final deviceInfoPlugin = DeviceInfoPlugin();
  final battery = Battery();
  final packageInfo = await PackageInfo.fromPlatform();

  String model = '';
  String os = '';
  String osVersion = '';

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfoPlugin.androidInfo;
    model = androidInfo.model ?? 'Unknown';
    os = 'Android';
    osVersion = androidInfo.version.release ?? 'Unknown';
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfoPlugin.iosInfo;
    model = iosInfo.utsname.machine ?? 'Unknown';
    os = 'iOS';
    osVersion = iosInfo.systemVersion ?? 'Unknown';
  }

  final batteryLevel = await battery.batteryLevel;
  final batteryState = await battery.batteryState;

  Position? position;
  double latitude = 0.0;
  double longitude = 0.0;
  String locationError = '';

  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        locationError = 'Permissão de localização negada';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      locationError = 'Permissão de localização permanentemente negada';
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      latitude = position.latitude;
      longitude = position.longitude;
    }
  } catch (e) {
    locationError = 'Erro ao obter localização: $e';
    print(locationError);
  }


  double freeDiskSpace = 0;
  double totalDiskSpace = 0;

  try {
    final directory = await getApplicationDocumentsDirectory();
    final stat = await directory.parent.stat();
    final statfs = FileStat.statSync(directory.parent.path);

    // These are estimates, as Flutter doesn't have direct access to full disk stats
    final freeSpace = await compute<String, int>((path) {
      return File(path).statSync().size;
    }, directory.path);

    // Use the values we can access
    freeDiskSpace = freeSpace.toDouble();

    // Get total storage indirectly (this is an estimate)
    final appDir = await getApplicationSupportDirectory();
    final appStat = await appDir.stat();
    totalDiskSpace = appStat.size.toDouble();
  } catch (e) {
    print("Error getting disk space: $e");
  }

  // // Convert to MB for readability (since we may not get accurate GB values)
  // final freeMB = (freeDiskSpace / (1024 * 1024)).toStringAsFixed(2);
  // final totalMB = (totalDiskSpace / (1024 * 1024)).toStringAsFixed(2);

  final freeGB = (freeDiskSpace / (1024 * 1024 * 1024)).toStringAsFixed(2);
  final totalGB = (totalDiskSpace / (1024 * 1024 * 1024)).toStringAsFixed(2);

  return {
    'device_id': deviceId,
    'sync_count': (prefs.getInt('sync_count') ?? 0) + 1,
    'first_sync': prefs.getString('first_sync') ?? DateTime.now().toIso8601String(),
    'last_sync': DateTime.now().toIso8601String(),
    'model': model,
    'os': os,
    'os_version': osVersion,
    'battery_level': batteryLevel,
    'battery_state': batteryState.toString(),
    'free_disk_space': '${freeGB}GB',
    'total_disk_space': '${totalGB}GB',
    'free_disk_space_bytes': freeDiskSpace,
    'total_disk_space_bytes': totalDiskSpace,
    'latitude': latitude,
    'longitude': longitude,
    'location_error': locationError,
  };
}