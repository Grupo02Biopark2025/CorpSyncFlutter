// device_detail_page.dart
import 'package:corp_syncmdm/modules/devices/devices_logs_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    _lastLogFuture = fetchLastLog();
  }

  Future<Map<String, dynamic>?> fetchLastLog() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:4040/api/devices/${widget.deviceId}/logs'),
      );

      if (response.statusCode == 200) {
        final logs = json.decode(response.body) as List;
        return logs.isNotEmpty ? logs.first : null;
      } else {
        throw Exception('Falha ao carregar o último log');
      }
    } catch (e) {
      throw Exception('Erro ao buscar log: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Dispositivo'),
        actions: [
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

              SizedBox(height: 12),


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
                      SizedBox(height: 24),

                      if (log['latitude'] != null && log['longitude'] != null)
                        _buildLocationSection(log),


                      SizedBox(height: 24),

                      Text(
                        'Último Log',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildLogCard(log),
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

  Widget _buildLogCard(Map<String, dynamic> log) {
    final batteryLevel = log['batteryLevel'] ?? 0;
    final batteryState = log['batteryState'] ?? '';

    Color batteryColor = Colors.green;
    if (batteryLevel < 20) {
      batteryColor = Colors.red;
    } else if (batteryLevel < 50) {
      batteryColor = Colors.orange;
    }

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
                Text(
                  'Sync #${log['syncCount'] ?? '0'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF259073),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              log['message'] ?? 'Sem mensagem',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Indicador de bateria
            Row(
              children: [
                Icon(
                  batteryState.toLowerCase().contains('charging')
                      ? Icons.battery_charging_full
                      : Icons.battery_full,
                  color: batteryColor,
                ),
                SizedBox(width: 8),
                Text(
                  '$batteryLevel%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: batteryColor,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  _formatBatteryState(batteryState),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
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

    // Remove o prefixo "BatteryState." se presente
    final cleanState = state.contains('.') ? state.split('.').last : state;

    // Converte para formato mais legível
    switch (cleanState.toLowerCase()) {
      case 'charging':
        return 'Carregando';
      case 'discharging':
        return 'Descarregando';
      case 'full':
        return 'Completo';
      default:
        return cleanState;
    }
  }
}