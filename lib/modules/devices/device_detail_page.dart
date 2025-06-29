// device_detail_page.dart
import 'package:corp_syncmdm/modules/devices/devices_logs_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:corp_syncmdm/services/notification_manager.dart';

class DeviceDetailPage extends StatefulWidget {
  final String deviceId;
  final String deviceModel;
  final Map<String, dynamic> deviceData;

  DeviceDetailPage({
    required this.deviceId,
    required this.deviceModel,
    required this.deviceData,
  });

  @override
  _DeviceDetailPageState createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  late Future<Map<String, dynamic>?> _lastLogFuture;
  final NotificationManager _notificationManager = NotificationManager();

  @override
  void initState() {
    super.initState();
    _lastLogFuture = fetchLastLog();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id');

      if (deviceId != null) {
        await _notificationManager.initialize(deviceId);
        print('✅ Notificações inicializadas para ${deviceId}');
      }
    } catch (error) {
      print('❌ Erro ao inicializar notificações: $error');
    }
  }

  Future<Map<String, dynamic>?> fetchLastLog() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:4040/api/devices/${widget.deviceId}/logs'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final logs = data['logs'] as List;
        return logs.isNotEmpty ? logs.first : null;
      } else {
        throw Exception('Falha ao carregar o último log');
      }
    } catch (e) {
      throw Exception('Erro ao buscar log: $e');
    }
  }

  // Método para exibir lista de notificações
  void _showNotificationsList() async {
    List<Map<String, dynamic>> notifications = [];

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:4040/api/notifications?limit=100'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        notifications = List<Map<String, dynamic>>.from(data['notifications']);
      }
    } catch (error) {
      print('❌ Erro: $error');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notificações (${notifications.length})',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Fechar'),
                ),
              ],
            ),
            SizedBox(height: 16),

            Expanded(
              child: notifications.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Nenhuma notificação'),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final isDelivered = notification['status'] == 'delivered';

                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    elevation: isDelivered ? 1 : 3,
                    child: ListTile(
                      leading: Icon(
                        Icons.notification_important,
                        color: Color(0xFF259073),
                      ),
                      title: Text(
                        notification['title'] ?? '',
                        style: TextStyle(
                          fontWeight: isDelivered ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification['message'] ?? ''),
                          SizedBox(height: 4),
                          Text(
                            'Status: ${notification['status']} • Device: ${notification['device']['model']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      trailing: !isDelivered ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color(0xFF259073),
                          shape: BoxShape.circle,
                        ),
                      ) : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

// Método para exibir dialog de envio de notificação
  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _NotificationDialog(deviceId: widget.deviceId);
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Dispositivo'),
        actions: [
          // Botão de notificações com contador
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _notificationManager.notificationListStream,
            builder: (context, snapshot) {
              final unreadCount = _notificationManager.getUnreadCount();

              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () => _showNotificationsList(),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Botão para enviar notificação
          IconButton(
            icon: Icon(Icons.notification_add),
            onPressed: () => _showNotificationDialog(),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _lastLogFuture = fetchLastLog();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informações do dispositivo
              _buildDeviceInfoCard(),
              SizedBox(height: 24),

              FutureBuilder<Map<String, dynamic>?>(
                future: _lastLogFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return _buildErrorCard(snapshot.error.toString());
                  } else if (!snapshot.hasData) {
                    return _buildNoLogCard();
                  }

                  final log = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Métricas rápidas
                      _buildQuickMetrics(log),
                      SizedBox(height: 24),

                      // Mapa se tiver localização
                      if (log['latitude'] != null && log['longitude'] != null &&
                          (log['latitude'] != 0 || log['longitude'] != 0))
                        _buildLocationSection(log),

                      SizedBox(height: 24),

                      // Último log detalhado
                      Text(
                        'Último Log',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildDetailedLogCard(log),
                    ],
                  );
                },
              ),

              SizedBox(height: 24),

              // Botão para ver todos os logs
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeviceLogsPage(
                          deviceId: widget.deviceId,
                          deviceModel: widget.deviceModel,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Color(0xFF259073),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Visualizar Todos os Logs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Métricas rápidas em cards pequenos
  Widget _buildQuickMetrics(Map<String, dynamic> log) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Atual',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Bateria', '${log['batteryLevel'] ?? 0}%',
                _getBatteryIcon(log['batteryState']), _getBatteryColor(log['batteryLevel'] ?? 0))),
            SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Armazenamento', '${log['diskUsedPercentage']?.toStringAsFixed(1) ?? '0'}% usado',
                Icons.storage, _getStorageColor(log['diskUsedPercentage'] ?? 0))),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Conexão', _formatConnectionType(log['connectionType']),
                _getConnectionIcon(log['connectionType']), Color(0xFF259073))),
            SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Velocidade', '${log['speed']?.toStringAsFixed(2) ?? '0.00'} m/s',
                Icons.speed, Colors.blue)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Card de log mais detalhado
  Widget _buildDetailedLogCard(Map<String, dynamic> log) {
    final batteryLevel = log['batteryLevel'] ?? 0;
    final batteryState = log['batteryState'] ?? '';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do log
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTimestamp(log['timestamp']),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF259073).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Sync #${log['syncCount'] ?? '0'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF259073),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Informações principais
            _buildLogInfoRow('Mensagem', log['message'] ?? 'Sem mensagem'),

            Divider(height: 24),

            // Seção de bateria
            Text('Bateria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getBatteryIcon(batteryState),
                  color: _getBatteryColor(batteryLevel),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text('$batteryLevel%',
                    style: TextStyle(fontWeight: FontWeight.w500, color: _getBatteryColor(batteryLevel))),
                SizedBox(width: 8),
                Text(_formatBatteryState(batteryState),
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),

            SizedBox(height: 16),

            // Seção de armazenamento
            Text('Armazenamento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            _buildLogInfoRow('Espaço livre', log['freeDiskSpace'] ?? 'N/A'),
            _buildLogInfoRow('Espaço total', log['totalDiskSpace'] ?? 'N/A'),
            _buildLogInfoRow('Percentual usado', '${log['diskUsedPercentage']?.toStringAsFixed(1) ?? '0'}%'),

            if (log['connectionType'] != null) ...[
              SizedBox(height: 16),
              Text('Conectividade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              _buildLogInfoRow('Tipo de conexão', _formatConnectionType(log['connectionType'])),
              if (log['wifiName'] != null)
                _buildLogInfoRow('Nome da rede', log['wifiName']),
            ],

            if (log['altitude'] != null || log['locationAccuracy'] != null) ...[
              SizedBox(height: 16),
              Text('Informações de Localização', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              if (log['altitude'] != null)
                _buildLogInfoRow('Altitude', '${log['altitude']}m'),
              if (log['locationAccuracy'] != null)
                _buildLogInfoRow('Precisão', '${log['locationAccuracy']}m'),
              if (log['speed'] != null)
                _buildLogInfoRow('Velocidade', '${log['speed']?.toStringAsFixed(2)} m/s'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Funções auxiliares para ícones e cores
  IconData _getBatteryIcon(String? state) {
    if (state?.toLowerCase().contains('charging') ?? false) {
      return Icons.battery_charging_full;
    }
    return Icons.battery_full;
  }

  Color _getBatteryColor(int level) {
    if (level < 20) return Colors.red;
    if (level < 50) return Colors.orange;
    return Colors.green;
  }

  Color _getStorageColor(double percentage) {
    if (percentage > 90) return Colors.red;
    if (percentage > 70) return Colors.orange;
    return Colors.green;
  }

  IconData _getConnectionIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'mobile':
        return Icons.signal_cellular_alt;
      case 'none':
        return Icons.signal_wifi_off;
      default:
        return Icons.network_check;
    }
  }

  String _formatConnectionType(String? type) {
    switch (type?.toLowerCase()) {
      case 'wifi':
        return 'Wi-Fi';
      case 'mobile':
        return 'Dados móveis';
      case 'none':
        return 'Sem conexão';
      default:
        return type ?? 'Desconhecido';
    }
  }

  Widget _buildLocationSection(Map<String, dynamic> log) {
    // Converter valores para double com segurança
    double latitude = 0.0;
    double longitude = 0.0;

    // Verificar se os valores existem e converter para double
    if (log['latitude'] != null) {
      // Se o valor for um inteiro grande (multiplicado por 1.000.000)
      if (log['latitude'] is int && (log['latitude'] as int).abs() > 10000) {
        latitude = (log['latitude'] as int) / 1000000.0;
      } else if (log['latitude'] is int) {
        latitude = (log['latitude'] as int).toDouble();
      } else if (log['latitude'] is double) {
        latitude = log['latitude'];
      } else if (log['latitude'] is String) {
        latitude = double.tryParse(log['latitude']) ?? 0.0;
      }
    }

    if (log['longitude'] != null) {
      // Se o valor for um inteiro grande (multiplicado por 1.000.000)
      if (log['longitude'] is int && (log['longitude'] as int).abs() > 10000) {
        longitude = (log['longitude'] as int) / 1000000.0;
      } else if (log['longitude'] is int) {
        longitude = (log['longitude'] as int).toDouble();
      } else if (log['longitude'] is double) {
        longitude = log['longitude'];
      } else if (log['longitude'] is String) {
        longitude = double.tryParse(log['longitude']) ?? 0.0;
      }
    }

    // Se não temos coordenadas válidas, usamos um valor padrão para o mapa
    if (latitude == 0.0 && longitude == 0.0) {
      latitude = -24.616861;  // Valor padrão para demonstração
      longitude = -53.710500; // Valor padrão para demonstração
    } else {
      // Verificar se os valores estão dentro dos limites válidos
      // Latitude: -90 a 90, Longitude: -180 a 180
      if (latitude < -90 || latitude > 90) {
        // Algo ainda está errado - usar valor padrão
        latitude = -24.616861;
      }
      if (longitude < -180 || longitude > 180) {
        // Algo ainda está errado - usar valor padrão
        longitude = -53.710500;
      }
    }


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Localização',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),

        Card(
          elevation: 3,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Mapa
              Container(
                height: 250,
                child: FlutterMap(
                  options: MapOptions(
                    center: LatLng(latitude, longitude),
                    zoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 40,
                          height: 40,
                          point: LatLng(latitude, longitude),
                          builder: (ctx) => Icon(
                            Icons.location_on,
                            color: Color(0xFF259073),
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Informações de localização
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF259073)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lat: ${latitude.toStringAsFixed(6)}, Long: ${longitude.toStringAsFixed(6)}',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        }
                      },
                      icon: Icon(Icons.map, color: Color(0xFF259073)),
                      label: Text('Abrir no Google Maps'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        side: BorderSide(color: Color(0xFF259073)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Funções existentes mantidas
  Widget _buildDeviceInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.phone_android,
                  size: 32,
                  color: Color(0xFF259073),
                ),
                SizedBox(width: 16),
                Text(
                  widget.deviceModel,
                  style: TextStyle(
                    fontSize: 24,





                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 32),
            _buildInfoRow('ID do Dispositivo', widget.deviceId),
            _buildInfoRow('Sistema Operacional',
                '${widget.deviceData['os']} ${widget.deviceData['osVersion']}'),
            _buildInfoRow('Espaço Total', widget.deviceData['totalDiskSpace'] ?? 'N/A'),
            _buildInfoRow('Espaço Livre', widget.deviceData['freeDiskSpace'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            SizedBox(height: 8),
            Text(
              'Erro ao carregar o log',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(error, style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLogCard() {
    return Card(
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.timer_off, color: Colors.grey, size: 32),
            SizedBox(height: 8),
            Text(
              'Nenhum log disponível',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Data desconhecida';

    try {
      final date = DateTime.parse(timestamp.toString());
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp.toString();
    }
  }

  String _formatBatteryState(String state) {
    if (state.isEmpty) return 'Desconhecido';

    final cleanState = state.contains('.') ? state.split('.').last : state;

    switch (cleanState.toLowerCase()) {
      case 'charging':
        return 'Carregando';
      case 'discharging':
        return 'Descarregando';
      case 'full':
        return 'Completo';
      case 'connectednotcharging':
        return 'Conectado (não carregando)';
      default:
        return cleanState;
    }
  }
}

class _NotificationDialog extends StatefulWidget {
  final String deviceId;

  _NotificationDialog({required this.deviceId});

  @override
  _NotificationDialogState createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<_NotificationDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'alert';
  String _selectedPriority = 'normal';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enviar Notificação',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLength: 50,
            ),
            SizedBox(height: 16),

            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Mensagem',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      DropdownMenuItem(value: 'alert', child: Text('Alerta')),
                      DropdownMenuItem(value: 'warning', child: Text('Aviso')),
                      DropdownMenuItem(value: 'info', child: Text('Informação')),
                    ],
                    onChanged: (value) => setState(() => _selectedType = value!),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration: InputDecoration(
                      labelText: 'Prioridade',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      DropdownMenuItem(value: 'low', child: Text('Baixa')),
                      DropdownMenuItem(value: 'normal', child: Text('Normal')),
                      DropdownMenuItem(value: 'high', child: Text('Alta')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                    ],
                    onChanged: (value) => setState(() => _selectedPriority = value!),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF259073),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text('Enviar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    Future<String?> _getCurrentDeviceId() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('device_id');
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:4040/api/notifications/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'deviceId': await _getCurrentDeviceId() ?? widget.deviceId,
          'title': _titleController.text.trim(),
          'message': _messageController.text.trim(),
          'type': _selectedType,
          'priority': _selectedPriority,
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notificação enviada com sucesso!'),
            backgroundColor: Color(0xFF259073),
          ),
        );
      } else {
        throw Exception('Falha ao enviar notificação');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}