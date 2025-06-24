import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  String? _deviceId;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _pingInterval = Duration(seconds: 30);

  // Stream controllers para diferentes tipos de mensagens
  final StreamController<Map<String, dynamic>> _notificationController =
  StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _connectionController =
  StreamController<String>.broadcast();

  // Getters para os streams
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;
  Stream<String> get connectionStream => _connectionController.stream;

  bool get isConnected => _channel != null && _channel!.closeCode == null;

  Future<void> connect(String deviceId) async {
    if (_isConnecting) return;

    _deviceId = deviceId;
    _isConnecting = true;
    _shouldReconnect = true;

    try {
      print('🔌 Conectando WebSocket para device: $deviceId');

      // URL do WebSocket - ajuste conforme seu ambiente
      final wsUrl = Platform.isAndroid
          ? 'ws://10.0.2.2:3001/ws?deviceId=$deviceId'
          : 'ws://localhost:3001/ws?deviceId=$deviceId';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Aguardar conexão
      await _channel!.ready;

      print('✅ WebSocket conectado!');
      _connectionController.add('connected');
      _isConnecting = false;
      _reconnectAttempts = 0;

      // Configurar listeners
      _setupListeners();

      // Iniciar ping
      _startPing();

    } catch (error) {
      print('❌ Erro ao conectar WebSocket: $error');
      _connectionController.add('error: $error');
      _isConnecting = false;

      if (_shouldReconnect) {
        _scheduleReconnect();
      }
    }
  }

  void _setupListeners() {
    _channel!.stream.listen(
          (data) {
        try {
          final Map<String, dynamic> message = json.decode(data);
          _handleMessage(message);
        } catch (error) {
          print('❌ Erro ao processar mensagem: $error');
        }
      },
      onError: (error) {
        print('❌ Erro no stream WebSocket: $error');
        _connectionController.add('error: $error');
        if (_shouldReconnect) {
          _scheduleReconnect();
        }
      },
      onDone: () {
        print('🔌 WebSocket desconectado');
        _connectionController.add('disconnected');
        _stopPing();
        if (_shouldReconnect) {
          _scheduleReconnect();
        }
      },
    );
  }

  void _handleMessage(Map<String, dynamic> message) {
    final String type = message['type'] ?? '';

    print('📨 Mensagem recebida: $type');

    switch (type) {
      case 'welcome':
        print('👋 Bem-vindo: ${message['data']['message']}');
        break;

      case 'notification':
        _handleNotification(message);
        break;

      case 'pong':
        print('🏓 Pong recebido');
        break;

      case 'admin_message':
        _handleAdminMessage(message);
        break;

      default:
        print('⚠️ Tipo de mensagem desconhecido: $type');
    }
  }

  void _handleNotification(Map<String, dynamic> message) {
    try {
      final notificationData = message['data'];

      print('🔔 Notificação recebida: ${notificationData['title']}');

      // Enviar para o stream
      _notificationController.add({
        'id': message['id'],
        'title': notificationData['title'],
        'message': notificationData['message'],
        'type': notificationData['notificationType'] ?? 'alert',
        'priority': notificationData['priority'] ?? 'normal',
        'timestamp': notificationData['timestamp'],
        'fromBulk': notificationData['fromBulk'] ?? false,
      });

      // Confirmar recebimento
      _sendMessage({
        'type': 'notification_received',
        'notificationId': message['id'],
        'deviceId': _deviceId,
      });

    } catch (error) {
      print('❌ Erro ao processar notificação: $error');
    }
  }

  void _handleAdminMessage(Map<String, dynamic> message) {
    print('📢 Mensagem administrativa: ${message['data']['message']}');

    // Tratar como notificação especial
    _notificationController.add({
      'title': 'Mensagem do Sistema',
      'message': message['data']['message'],
      'type': 'admin',
      'priority': message['data']['priority'] ?? 'high',
      'timestamp': message['data']['timestamp'],
      'isAdmin': true,
    });
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (isConnected) {
      try {
        _channel!.sink.add(json.encode(message));
      } catch (error) {
        print('❌ Erro ao enviar mensagem: $error');
      }
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      if (isConnected) {
        _sendMessage({
          'type': 'ping',
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ Máximo de tentativas de reconexão atingido');
      _connectionController.add('max_attempts_reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    print('🔄 Reagendando reconexão (tentativa $_reconnectAttempts/$_maxReconnectAttempts)');

    _reconnectTimer = Timer(_reconnectDelay, () {
      if (_shouldReconnect && _deviceId != null) {
        connect(_deviceId!);
      }
    });
  }

  void sendDeviceInfo(Map<String, dynamic> deviceInfo) {
    _sendMessage({
      'type': 'device_info',
      'data': deviceInfo,
    });
  }

  void markNotificationAsRead(String notificationId) {
    _sendMessage({
      'type': 'notification_read',
      'data': {
        'notificationId': notificationId,
        'deviceId': _deviceId,
        'readAt': DateTime.now().toIso8601String(),
      }
    });
  }

  void sendHeartbeat() {
    _sendMessage({
      'type': 'heartbeat',
      'data': {
        'deviceId': _deviceId,
        'timestamp': DateTime.now().toIso8601String(),
        'battery': 'unknown', // Você pode obter info real da bateria
      }
    });
  }

  void disconnect() {
    print('🔌 Desconectando WebSocket...');

    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _stopPing();

    try {
      _channel?.sink.close();
    } catch (error) {
      print('❌ Erro ao fechar WebSocket: $error');
    }

    _channel = null;
    _connectionController.add('disconnected');
  }

  void reconnect() {
    if (_deviceId != null) {
      disconnect();
      Future.delayed(Duration(seconds: 2), () {
        connect(_deviceId!);
      });
    }
  }

  void dispose() {
    disconnect();
    _notificationController.close();
    _connectionController.close();
  }
}