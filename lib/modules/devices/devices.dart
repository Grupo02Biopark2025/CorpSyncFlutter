import 'package:corp_syncmdm/modules/devices/device_detail_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DevicesPage extends StatefulWidget {
  @override
  _DevicesPageState createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _devices = [];
  ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _fetchDevices();

    _scrollController.addListener(() {
      setState(() {
        _showScrollToTop = _scrollController.offset > 300;
      });

      // Detectar quando o usuário rola para baixo para carregar mais
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _currentPage < _totalPages) {
        _loadMoreDevices();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchDevices({String? search}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String url = 'http://10.0.2.2:4040/api/devices/?page=$_currentPage&limit=15';
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // Se for a primeira página, substitui a lista, senão adiciona
          if (_currentPage == 1) {
            _devices = data['devices'];
          } else {
            _devices.addAll(data['devices']);
          }
          _totalPages = data['totalPages'];
          _isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar dispositivos');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dispositivos: $e')),
      );
    }
  }

  Future<void> _loadMoreDevices() async {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
      await _fetchDevices(search: _searchController.text);
    }
  }

  Future<void> _refreshDevices() async {
    setState(() {
      _currentPage = 1;
    });
    await _fetchDevices(search: _searchController.text);
  }

  void _onSearch(String query) {
    setState(() {
      _currentPage = 1;
      _devices = []; // Limpa a lista para nova busca
    });
    _fetchDevices(search: query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho e barra de pesquisa
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dispositivos',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF259073),
                        ),
                      ),
                      IconButton(
                        icon: Icon(_isSearching ? Icons.close : Icons.search),
                        onPressed: () {
                          setState(() {
                            _isSearching = !_isSearching;
                            if (!_isSearching) {
                              _searchController.clear();
                              _refreshDevices();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (_isSearching)
                    Container(
                      height: 48,
                      margin: EdgeInsets.only(top: 8, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Pesquisar por modelo ou SO...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onSubmitted: _onSearch,
                      ),
                    ),
                  SizedBox(height: 8),
                  Text(
                    '${_devices.length} dispositivos encontrados',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1),

            // Lista de dispositivos
            Expanded(
              child: _isLoading && _devices.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : _devices.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.devices_other, size: 70, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'Nenhum dispositivo encontrado',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    if (_isSearching)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Tente uma pesquisa diferente',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _refreshDevices,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  itemCount: _devices.length + (_currentPage < _totalPages ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Indicador de carregamento no final da lista
                    if (index == _devices.length) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final device = _devices[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: _buildDeviceCard(device),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
        mini: true,
        backgroundColor: Color(0xFF259073),
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        child: Icon(Icons.arrow_upward),
      )
          : null,
    );
  }

  Widget _buildDeviceCard(dynamic device) {
    // Calcular o status (online/offline) baseado no último log
    final bool isOnline = false; // Substitua por lógica real baseada nos logs
    final String osInfo = '${device['os'] ?? 'Desconhecido'} ${device['osVersion'] ?? ''}';
    final String modelName = device['model'] ?? 'Modelo desconhecido';

    // Extrair as primeiras letras do modelo para o avatar
    final String avatarText = modelName.split(' ')
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();

    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceDetailPage(
                deviceId: device['deviceId'],
                deviceModel: modelName,
                deviceData: device,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar com iniciais do modelo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(0xFF259073).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: avatarText.isEmpty
                      ? Icon(Icons.phone_android, size: 30, color: Color(0xFF259073))
                      : Text(
                    avatarText,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF259073),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),

              // Informações do dispositivo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            modelName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isOnline ? 'Online' : 'Online',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isOnline ? Colors.green : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),

                    // Sistema operacional com ícone
                    Row(
                      children: [
                        Icon(getOSIcon(device['os']), size: 14, color: Colors.grey[600]),
                        SizedBox(width: 6),
                        Text(
                          osInfo,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),

                    // Espaço de armazenamento
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: getStoragePercentage(device),
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(getStorageColor(getStoragePercentage(device))),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${device['freeDiskSpace'] ?? 'N/A'} livres',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),

                    SizedBox(height: 6),
                    Text(
                      _truncateDeviceId(device['deviceId']),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Função auxiliar para obter o ícone do sistema operacional
  IconData getOSIcon(String? os) {
    if (os == null) return Icons.devices;
    if (os.toLowerCase().contains('android')) return Icons.android;
    if (os.toLowerCase().contains('ios')) return Icons.phone_iphone;
    return Icons.devices;
  }

  // Função auxiliar para truncar e formatar o ID do dispositivo
  String _truncateDeviceId(String? deviceId) {
    if (deviceId == null || deviceId.length <= 12) return 'ID: ${deviceId ?? 'N/A'}';
    return 'ID: ${deviceId.substring(0, 8)}...${deviceId.substring(deviceId.length - 4)}';
  }

  // Função para calcular a porcentagem de armazenamento usado
  double getStoragePercentage(dynamic device) {
    try {
      if (device['freeDiskSpace'] == null || device['totalDiskSpace'] == null) return 0.5;

      // Extrair os valores numéricos das strings (ex: "10.5GB" -> 10.5)
      final freePattern = RegExp(r'(\d+\.?\d*)');
      final totalPattern = RegExp(r'(\d+\.?\d*)');

      final freeMatch = freePattern.firstMatch(device['freeDiskSpace']);
      final totalMatch = totalPattern.firstMatch(device['totalDiskSpace']);

      if (freeMatch == null || totalMatch == null) return 0.5;

      final freeSpace = double.tryParse(freeMatch.group(1) ?? '0') ?? 0;
      final totalSpace = double.tryParse(totalMatch.group(1) ?? '1') ?? 1;

      if (totalSpace <= 0) return 0.0;

      // Calcula o espaço usado (invertido da barra de progresso)
      final usedPercentage = 1.0 - (freeSpace / totalSpace);
      return usedPercentage.clamp(0.0, 1.0);
    } catch (e) {
      return 0.5; // Valor padrão em caso de erro
    }
  }

  // Função para definir a cor do armazenamento baseado na porcentagem
  Color getStorageColor(double percentage) {
    if (percentage > 0.9) return Colors.red;
    if (percentage > 0.7) return Colors.orange;
    return Color(0xFF259073);
  }
}