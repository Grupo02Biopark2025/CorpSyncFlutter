// import 'dart:async';
//
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:battery_plus/battery_plus.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// Future<void> syncDeviceData() async {
//   try {
//     final firestore = FirebaseFirestore.instance;
//     final deviceInfo = DeviceInfoPlugin();
//     final battery = Battery();
//
//     final prefs = await SharedPreferences.getInstance();
//     // String? deviceId = prefs.getString("device_id");
//     String? deviceId = "teste"; // Para teste, remova isso depois
//     if (deviceId == null) {
//       var androidInfo = await deviceInfo.androidInfo;
//       deviceId = androidInfo.id;
//       prefs.setString("device_id", deviceId);
//     }
//
//     var androidInfo = await deviceInfo.androidInfo;
//     var batteryLevel = await battery.batteryLevel;
//
//     Map<String, dynamic> deviceData = {
//       "model": androidInfo.model,
//       "os": "Android ${androidInfo.version.release}",
//       "serial": androidInfo.id,
//       "imei": "N/A",
//       "battery": batteryLevel,
//       "storage": "128GB",
//       "lastSync": DateTime.now().toIso8601String(),
//     };
//
//     await firestore.collection("devices").doc(deviceId).set(deviceData, SetOptions(merge: true));
//
//     print("Dados sincronizados!");
//   } catch (e) {
//     print("Erro ao sincronizar dados do dispositivo: $e");
//   }
// }
//
// @pragma('vm:entry-point')
// void onBackgroundTask(ServiceInstance service) async {
//   await Firebase.initializeApp(
//     options: const FirebaseOptions(
//       apiKey: "AIzaSyBzjfp1r1Qh1KigA-UfYzrv5IYJ-ha_730",
//       appId: "1:159705809298:android:e0f5535f0ca7ed497f814b",
//       messagingSenderId: "159705809298",
//       projectId: "corpsync-874ab",
//     ),
//   );
//
//   final prefs = await SharedPreferences.getInstance();
//   bool ativarSync = prefs.getBool("ativar_sync") ?? false;
//
//   if (!ativarSync) {
//     print("Sincronização não autorizada. QR não escaneado ainda.");
//     return;
//   }
//
//   await syncDeviceData();
//
//   Timer.periodic(const Duration(seconds: 60), (timer) async {
//     final prefs = await SharedPreferences.getInstance();
//     bool ativarSync = prefs.getBool("ativar_sync") ?? false;
//
//     if (ativarSync) {
//       await syncDeviceData();
//     } else {
//       print("Sincronização desativada durante execução.");
//     }
//   });
// }
//
