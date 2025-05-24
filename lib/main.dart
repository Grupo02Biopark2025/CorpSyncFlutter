import 'dart:io';
import 'package:corp_syncmdm/services/native_stats.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:corp_syncmdm/modules/user/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'app.dart';
import 'theme/theme_notifier.dart';
import 'services/workmanager_sync.dart';

Future<void> requestAllPermissions() async {
  await requestLocationPermission();

  if (Platform.isAndroid) {
    await requestUsageStatsPermission();
  }
}

Future<bool> requestLocationPermission() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print("Os serviços de localização estão desativados");

    if (Platform.isAndroid) {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.settings.LOCATION_SOURCE_SETTINGS',
      );
      await intent.launch();
    }

    return false;
  }

  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.deniedForever) {
    print("As permissões de localização foram negadas permanentemente");

    if (Platform.isAndroid) {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:com.example.corp_syncmdm',
      );
      await intent.launch();
    }

    return false;
  }

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print("Permissão de localização negada");
      return false;
    }
  }

  print("Permissão de localização atual: $permission");
  return permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;
}

Future<bool> requestUsageStatsPermission() async {
  if (!Platform.isAndroid) return true;

  try {
    bool hasPermission = await NativeStatsService.hasUsageStatsPermission();
    if (!hasPermission) {
      await NativeStatsService.requestUsageStatsPermission();
      print("Por favor, habilite o acesso às estatísticas de uso para o app");
      return false;
    }
    print("Permissão de estatísticas de uso já concedida");
    return true;
  } catch (e) {
    print("Erro ao solicitar permissão de estatísticas de uso: $e");
    return false;
  }
}

Future<bool> checkAndRequestPermissions() async {
  bool locationPermission = await requestLocationPermission();

  bool usageStatsPermission = true;
  if (Platform.isAndroid) {
    usageStatsPermission = await requestUsageStatsPermission();
  }

  return locationPermission && usageStatsPermission;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBzjfp1r1Qh1KigA-UfYzrv5IYJ-ha_730",
      appId: "1:159705809298:android:e0f5535f0ca7ed497f814b",
      messagingSenderId: "159705809298",
      projectId: "corpsync-874ab",
    ),
  );

  await initializeWorkManager();

  final prefsSync = await SharedPreferences.getInstance();
  final ativarSync = prefsSync.getBool("ativar_sync") ?? false;
  if(ativarSync) {
    await checkAndRequestPermissions();
    await startPeriodicSyncAfterQRScan();
  } else {
    await requestLocationPermission();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
      ],
      child: MyApp(),
    ),
  );
}