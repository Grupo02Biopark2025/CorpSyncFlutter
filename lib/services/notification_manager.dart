import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'websocket_service.dart';
import 'notification_service.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final WebSocketService _webSocketService = WebSocketService();
  final NotificationService _notificationService = NotificationService();

  StreamSubscription? _notificationSubscription;
  StreamSubscription? _connectionSubscription;

  String? _currentDeviceId;
  bool _isInitialized = false;

  // Lista de notificações recebidas (em memória)
  final List<Map<String, dynamic>> _notifications = [];

  // Stream controller para notificar mudanças na lista
  final StreamController<List<Map<String, dynamic>>> _notificationListController =
  StreamController<List<Map<String, dynamic>>>.broadcast();

  // Getters
  Stream<List<Map<String, dynamic>>> get notificationListStream =>
      _notificationListController.stream;
  List<Map<String, dynamic>> get notifications => List.unmodifiable(_notifications);
  bool get isConnected => _webSocketService.isConnected;
  String? get deviceId => _currentDeviceId;

  Future<void> initialize(String deviceId) async {
    if (_isInitialized && _currentDeviceId == deviceId) return;

    _currentDeviceId = deviceId;
    print('🚀 Inicializando NotificationManager para device: $deviceId');

    // Inicializar serviços
    await _notificationService.initialize();
    await _notificationService.requestPermissions();

    // Configurar listeners
    _setupListeners();

    // Conectar WebSocket
    await _webSocketService.connect(deviceId);

    _isInitialized = true;
    print('✅ NotificationManager inicializado');
  }

  void _setupListeners() {
    // Cancelar listeners anteriores
    _notificationSubscription?.cancel();
    _connectionSubscription?.cancel();

    // Listener para notificações
    _notificationSubscription = _webSocketService.notificationStream.listen(
          (notification) {
        _handleNewNotification(notification);
      },
      onError: (error) {
        print('❌ Erro no stream de notificações: $error');
      },
    );

    // Listener para status de conexão
    _connectionSubscription = _webSocketService.connectionStream.listen(
          (status) {
        _handleConnectionStatus(status);
      },
      onError: (error) {
        print('❌ Erro no stream de conexão: $error');
      },
    );
  }

  void _handleNewNotification(Map<String, dynamic> notification) {
    print('🔔 Nova notificação: ${notification['title']}');

    notification['receivedAt'] = DateTime.now().toIso8601String();
    notification['isRead'] = false;

    // Adicionar à lista
    _notifications.insert(0, notification);

    if (_notifications.length > 100) {
      _notifications.removeRange(100, _notifications.length);
    }

    _notificationListController.add(_notifications);

    _showLocalNotification(notification);

    if (notification['id'] != null) {
      _webSocketService.markNotificationAsRead(notification['id'].toString());
    }
  }

  void _handleConnectionStatus(String status) {
    print('🔌 Status da conexão: $status');

    if (status == 'connected') {
      // Enviar informações do dispositivo quando conectar
      _sendDeviceInfo();
    }
  }

  void addExistingNotification(Map<String, dynamic> notification) {
    print('🔍 Tentando adicionar notificação: ${notification['title']}');
    print('🔍 Lista atual tem: ${_notifications.length} itens');

    // Verificar se já existe para evitar duplicatas
    final existingIndex = _notifications.indexWhere(
            (n) => n['id'].toString() == notification['id'].toString()
    );

    if (existingIndex == -1) {
      _notifications.add(notification);

      // Ordenar por data (mais recente primeiro)
      _notifications.sort((a, b) {
        final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(1900);
        final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(1900);
        return bTime.compareTo(aTime);
      });

      print('✅ Notificação adicionada! Lista agora tem: ${_notifications.length} itens');

      // Notificar mudança na lista
      _notificationListController.add(_notifications);
    } else {
      print('⚠️ Notificação já existe na lista');
    }
  }


  Future<void> _showLocalNotification(Map<String, dynamic> notification) async {
    try {
      await _notificationService.showNotification(
        title: notification['title'] ?? 'Notificação MDM',
        message: notification['message'] ?? '',
        type: notification['type'] ?? 'alert',
        priority: notification['priority'] ?? 'normal',
        payload: notification['id']?.toString(),
      );
    } catch (error) {
      print('❌ Erro ao exibir notificação local: $error');
    }
  }

  void _sendDeviceInfo() {
    // Você pode obter informações reais do dispositivo aqui
    final deviceInfo = {
      'platform': defaultTargetPlatform.name,
      'appVersion': '1.0.0', // Obter da package_info
      'lastSeen': DateTime.now().toIso8601String(),
      'capabilities': ['push_notifications', 'websocket'],
    };

    _webSocketService.sendDeviceInfo(deviceInfo);
  }


  void markAsRead(String notificationId) {
    try {
      final index = _notifications.indexWhere((n) => n['id'].toString() == notificationId);

      if (index != -1) {
        _notifications[index]['isRead'] = true;
        _notifications[index]['readAt'] = DateTime.now().toIso8601String();

        // Notificar mudança
        _notificationListController.add(_notifications);

        // Informar o servidor
        _webSocketService.markNotificationAsRead(notificationId);

        print('👀 Notificação marcada como lida: $notificationId');
      }
    } catch (error) {
      print('❌ Erro ao marcar notificação como lida: $error');
    }
  }

  void clearNotification(String notificationId) {
    try {
      _notifications.removeWhere((n) => n['id'].toString() == notificationId);
      _notificationListController.add(_notifications);
      print('🗑️ Notificação removida: $notificationId');
    } catch (error) {
      print('❌ Erro ao remover notificação: $error');
    }
  }

  void clearAllNotifications() {
    _notifications.clear();
    _notificationListController.add(_notifications);
    _notificationService.cancelAll();
    print('🗑️ Todas as notificações removidas');
  }

  int getUnreadCount() {
    return _notifications.where((n) => !(n['isRead'] ?? false)).length;
  }

  List<Map<String, dynamic>> getUnreadNotifications() {
    return _notifications.where((n) => !(n['isRead'] ?? false)).toList();
  }

  void reconnect() {
    print('🔄 Reconectando...');
    _webSocketService.reconnect();
  }

  void disconnect() {
    print('🔌 Desconectando NotificationManager...');
    _webSocketService.disconnect();
  }

  void dispose() {
    _notificationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _notificationListController.close();
    _webSocketService.dispose();
    _isInitialized = false;
    print('🗑️ NotificationManager disposed');
  }
}