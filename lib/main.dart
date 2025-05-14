import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:corp_syncmdm/modules/user/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'theme/theme_notifier.dart';
import 'services/workmanager_sync.dart';

Future<void> requestLocationPermission() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print("Os serviços de localização estão desativados");
    return;
  }

  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.deniedForever) {
    print("As permissões de localização foram negadas permanentemente");
    return;
  }

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return;
    }
  }

}

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  await requestLocationPermission();

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
    await startPeriodicSyncAfterQRScan();
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