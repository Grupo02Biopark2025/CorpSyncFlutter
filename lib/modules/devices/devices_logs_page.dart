import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DeviceLogsPage extends StatefulWidget {
  final String deviceId;
  final String deviceModel;

  DeviceLogsPage({required this.deviceId, required this.deviceModel});

  @override
  _DeviceLogsPageState createState() => _DeviceLogsPageState();
}

class _DeviceLogsPageState extends State<DeviceLogsPage> {
  late Future<Map<String, dynamic>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = fetchDeviceLogs();
  }

  Future<Map<String, dynamic>> fetchDeviceLogs() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:4040/api/devices/${widget.deviceId}/logs'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao carregar logs do dispositivo');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logs - ${widget.deviceModel}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _logsFuture = fetchDeviceLogs();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('Nenhum log encontrado para este dispositivo'));
          }

          final data = snapshot.data!;
          final logs = data['logs'] as List? ?? [];
          final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

          if (logs.isEmpty) {
            return Center(child: Text('Nenhum log encontrado para este dispositivo'));
          }

          return Column(
            children: [
              // Header com estatísticas
              _buildStatsHeader(logs, pagination),

              // Lista de logs
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _logsFuture = fetchDeviceLogs();
                    });
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildEnhancedLogCard(log, index);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(List logs, Map<String, dynamic> pagination) {
    if (logs.isEmpty) return SizedBox();

    // Calcular algumas estatísticas básicas
    final totalLogs = pagination['totalLogs'] ?? logs.length;
    final avgBattery = logs.map((log) => log['batteryLevel'] ?? 0)
        .reduce((a, b) => a + b) / logs.length;

    final latestLog = logs.first;
    final connectionType = latestLog['connectionType'] ?? 'unknown';

    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total de Logs',
                  totalLogs.toString(),
                  Icons.history,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Bateria Média',
                  '${avgBattery.toStringAsFixed(0)}%',
                  Icons.battery_full,
                  _getBatteryColor(avgBattery.toInt()),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Conexão',
                  _formatConnectionType(connectionType),
                  _getConnectionIcon(connectionType),
                  Color(0xFF259073),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedLogCard(Map<String, dynamic> log, int index) {
    final batteryLevel = log['batteryLevel'] ?? 0;
    final batteryState = log['batteryState'] ?? '';

    // Conversões seguras
    double diskUsedPercentage = _toDouble(log['diskUsedPercentage']);
    double speed = _toDouble(log['speed']);
    double latitude = _toDouble(log['latitude']);
    double longitude = _toDouble(log['longitude']);

    // Corrigir coordenadas se necessário (valores grandes dividir por 1M)
    if (latitude.abs() > 1000) latitude = latitude / 1000000;
    if (longitude.abs() > 1000) longitude = longitude / 1000000;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ExpansionTile(
          tilePadding: EdgeInsets.all(16),
          childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFF259073).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '#${log['syncCount'] ?? index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF259073),
                ),
              ),
            ),
          ),
          title: Text(
            _formatTimestamp(log['timestamp']),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                _buildQuickInfo(Icons.battery_full, '$batteryLevel%', _getBatteryColor(batteryLevel)),
                SizedBox(width: 16),
                _buildQuickInfo(Icons.storage, '${diskUsedPercentage.toStringAsFixed(0)}%', _getStorageColor(diskUsedPercentage)),
                SizedBox(width: 16),
                _buildQuickInfo(_getConnectionIcon(log['connectionType']),
                    _formatConnectionType(log['connectionType']), Color(0xFF259073)),
              ],
            ),
          ),
          children: [
            _buildDetailedLogContent(log, latitude, longitude, speed, diskUsedPercentage),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedLogContent(Map<String, dynamic> log, double latitude, double longitude, double speed, double diskUsedPercentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(),

        // Mensagem
        _buildDetailSection('Mensagem', [
          _buildDetailRow('Descrição', log['message'] ?? 'Sem mensagem'),
        ]),

        // Bateria
        _buildDetailSection('Bateria', [
          Row(
            children: [
              Icon(_getBatteryIcon(log['batteryState']),
                  color: _getBatteryColor(log['batteryLevel'] ?? 0), size: 20),
              SizedBox(width: 8),
              Text(
                '${log['batteryLevel'] ?? 0}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getBatteryColor(log['batteryLevel'] ?? 0),
                ),
              ),
              SizedBox(width: 8),
              Text(
                _formatBatteryState(log['batteryState'] ?? ''),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ]),

        // Armazenamento
        _buildDetailSection('Armazenamento', [
          _buildDetailRow('Espaço livre', log['freeDiskSpace'] ?? 'N/A'),
          _buildDetailRow('Espaço total', log['totalDiskSpace'] ?? 'N/A'),
          _buildDetailRow('Usado', '${diskUsedPercentage.toStringAsFixed(1)}%'),
        ]),

        // Conectividade
        if (log['connectionType'] != null)
          _buildDetailSection('Conectividade', [
            _buildDetailRow('Tipo', _formatConnectionType(log['connectionType'])),
            if (log['wifiName'] != null)
              _buildDetailRow('Wi-Fi', log['wifiName']),
          ]),

        // Localização
        if (latitude != 0 || longitude != 0)
          _buildDetailSection('Localização', [
            _buildDetailRow('Coordenadas', '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}'),
            if (log['altitude'] != null)
              _buildDetailRow('Altitude', '${log['altitude']}m'),
            if (log['locationAccuracy'] != null)
              _buildDetailRow('Precisão', '${log['locationAccuracy']}m'),
            _buildDetailRow('Velocidade', '${speed.toStringAsFixed(2)} m/s'),
          ]),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF259073),
            ),
          ),
          SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Funções auxiliares
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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

  IconData _getBatteryIcon(String? state) {
    if (state?.toLowerCase().contains('charging') ?? false) {
      return Icons.battery_charging_full;
    }
    return Icons.battery_full;
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