import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corp_syncmdm/modules/user/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'theme/theme_notifier.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBxPSapzKtuKTMDlBbXKWAVw2BQJc2y9so",
      appId: "1:22000336342:android:3ad389218086b7d7553877",
      messagingSenderId: "22000336342",
      projectId: "corpsync-mdm",
    ),
  );

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