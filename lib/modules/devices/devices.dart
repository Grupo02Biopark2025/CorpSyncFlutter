import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DevicesPage extends StatefulWidget {
  @override
  _DevicesPageState createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  Future<List<dynamic>> fetchDevices() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:4040/api/devices/'));

    if (response.statusCode == 200) {
      return json.decode(response.body) as List;
    } else {
      throw Exception('Falha ao carregar dispositivos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lista de Dispositivos')),
      body: FutureBuilder<List<dynamic>>(
        future: fetchDevices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nenhum dispositivo encontrado'));
          }

          final devices = snapshot.data!;
          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: GestureDetector(
                  onTap: () {
                    // Inserir redirecionamento pra tela dos logs
                  },
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Icon(Icons.phone_android, size: 20, color: Color(0xFF259073)),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device['model'] ?? 'Modelo desconhecido',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text('SO: ${device['os']} ${device['osVersion']}'),
                                Text('ID: ${device['deviceId']}'),
                                Text('Espaço Total: ${device['totalDiskSpace']}'),
                                Text('Espaço Livre: ${device['freeDiskSpace']}'),
                              ],
                            ),
                          ),
                        ],
                      ),
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
}
