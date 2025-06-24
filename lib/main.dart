import 'dart:io';
import 'package:corp_syncmdm/services/native_stats.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:corp_syncmdm/modules/user/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'app.dart';
import 'theme/theme_notifier.dart';
import 'services/workmanager_sync.dart';
import 'package:corp_syncmdm/services/notification_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ClickAnalyticsObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackNavigation(route.settings.name ?? route.runtimeType.toString());
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _trackNavigation('back_to_${previousRoute.settings.name ?? previousRoute.runtimeType.toString()}');
    }
  }

  void _trackNavigation(String routeName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id');

      if (userId != null) {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:4040/api/users/$userId/click'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(Duration(seconds: 5));

        print('📊 Navigation tracked: $routeName for user $userId');
      }
    } catch (e) {
      print('❌ Error tracking navigation: $e');
    }
  }
}

// Classe para rastrear clicks gerais
class AnalyticsService {
  static void trackClick(String actionName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id');

      if (userId != null) {
        await http.post(
          Uri.parse('http://10.0.2.2:4040/api/users/$userId/click'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(Duration(seconds: 5));

        print('📊 Click tracked: $actionName for user $userId');
      }
    } catch (e) {
      print('❌ Error tracking click: $e');
    }
  }

  static void trackLogin(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userId);

      await http.post(
        Uri.parse('http://10.0.2.2:4040/api/users/$userId/login'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      print('🔑 Login tracked for user: $userId');
    } catch (e) {
      print('❌ Error tracking login: $e');
    }
  }

  static void clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');
      print('👋 User session cleared');
    } catch (e) {
      print('❌ Error clearing user: $e');
    }
  }
}

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


// Adicione esta função após checkAndRequestPermissions()
Future<void> initializeNotifications() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id'); // ou o nome da chave que você usa

    if (deviceId != null && deviceId.isNotEmpty) {
      final NotificationManager notificationManager = NotificationManager();

      print('📱 Inicializando notificações para dispositivo: $deviceId');
      await notificationManager.initialize(deviceId);
      print('✅ Sistema de notificações inicializado');
    } else {
      print('ℹ️ DeviceId não encontrado, notificações não serão inicializadas');
    }
  } catch (e) {
    print('❌ Erro ao inicializar notificações: $e');
  }
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

  await initializeNotifications();

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