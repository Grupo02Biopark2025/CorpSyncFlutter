import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Configurações Android
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configurações iOS
    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configurações gerais
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // await _testNotification();
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    print('✅ Serviço de notificações locais inicializado');
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notificação tocada: ${response.payload}');
    // Aqui você pode navegar para uma tela específica
    // ou executar alguma ação baseada no payload
  }

  Future<void> showNotification({
    required String title,
    required String message,
    String type = 'alert',
    String priority = 'normal',
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // ID único para cada notificação
    final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    // Configurações Android
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'mdm_notifications',
      'MDM Notifications',
      channelDescription: 'Notificações do sistema MDM',
      importance: _getImportance(priority),
      priority: _getPriority(priority),
      icon: _getIcon(type),
      color: _getColor(type),
      enableVibration: priority == 'urgent' || priority == 'high',
      playSound: true,
    );

    // Configurações iOS
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      message,
      details,
      payload: payload,
    );

    print('🔔 Notificação local exibida: $title');
  }

  Future<void> _testNotification() async {
    try {
      await showNotification(
        title: 'Teste de Notificação',
        message: 'Se você vê esta mensagem, as notificações estão funcionando!',
        type: 'info',
        priority: 'normal',
      );
      print('🧪 Notificação de teste enviada');
    } catch (error) {
      print('❌ Erro na notificação de teste: $error');
    }
  }

  Importance _getImportance(String priority) {
    switch (priority) {
      case 'urgent':
        return Importance.max;
      case 'high':
        return Importance.high;
      case 'low':
        return Importance.low;
      default:
        return Importance.defaultImportance;
    }
  }

  Priority _getPriority(String priority) {
    switch (priority) {
      case 'urgent':
        return Priority.max;
      case 'high':
        return Priority.high;
      case 'low':
        return Priority.low;
      default:
        return Priority.defaultPriority;
    }
  }

  String _getIcon(String type) {
    return '@mipmap/ic_launcher';
  }

  Color _getColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'admin':
        return Colors.purple;
      default:
        return const Color(0xFF259073);
    }
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation();
      AndroidFlutterLocalNotificationsPlugin();

      if (androidImplementation != null) {
        // Para Android 13+ (API 33+)
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        print('🔔 Permissão de notificação: ${granted == true ? "✅ Concedida" : "❌ Negada"}');
        return granted ?? false;
      }
    }

    return true;
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}