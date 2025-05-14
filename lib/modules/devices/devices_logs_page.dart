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
  Future<List<dynamic>> fetchDeviceLogs() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:4040/api/devices/${widget.deviceId}/logs'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List;
    } else {
      throw Exception('Falha ao carregar logs do dispositivo');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logs - ${widget.deviceModel}'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchDeviceLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nenhum log encontrado para este dispositivo'));
          }

          final logs = snapshot.data!;
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTimestamp(log['timestamp']),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            _buildLogTypeIndicator(log['type']),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          log['message'] ?? 'Sem mensagem',
                          style: TextStyle(fontSize: 16),
                        ),
                        if (log['details'] != null) ...[
                          SizedBox(height: 8),
                          Text(
                            log['details'],
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
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

  Widget _buildLogTypeIndicator(String? type) {
    Color color;
    IconData icon;
    String label = type ?? 'info';

    switch (type?.toLowerCase()) {
      case 'error':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'warning':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case 'info':
      default:
        color = Color(0xFF259073);
        icon = Icons.info;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}