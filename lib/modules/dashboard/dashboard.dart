import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};

  int _osVersionCurrentPage = 0;
  final int _osVersionItemsPerPage = 5;
  final Color primaryColor = Color(0xFF259073);
  final Color darkBlueColor = Color(0xFF082142);
  final Color lightGreenColor = Color(0xFF7FDA89);
  final Color paleGreenColor = Color(0xFFC8E98E);
  final Color yellowGreenColor = Color(0xFFE6F99D);
  final Color orangeColor = Colors.orange;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final devicesResponse = await http
          .get(
            Uri.parse('http://10.0.2.2:4040/api/devices'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      final usersResponse = await http
          .get(
            Uri.parse('http://10.0.2.2:4040/api/users'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (devicesResponse.statusCode == 200 &&
          usersResponse.statusCode == 200) {
        final devicesData = json.decode(devicesResponse.body);
        final usersData = json.decode(usersResponse.body);
        setState(() {
          _dashboardData = _processDashboardData(devicesData, usersData);
          _osVersionCurrentPage = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar dados do dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _processDashboardData(
    Map<String, dynamic> devicesData,
    List<dynamic> usersData,
  ) {
    final devices = devicesData['devices'] as List<dynamic>;

    int totalDevices = devices.length;
    int onlineDevices = devices.where((d) => d['isOnline'] == true).length;
    int offlineDevices = totalDevices - onlineDevices;

    double avgScreenTime = 0;
    int validScreenTimeCount = 0;

    Map<String, int> osVersions = {};

    Map<String, int> brands = {};
    for (var device in devices) {
      if (device['screenTimeMinutes'] != null &&
          device['screenTimeMinutes'] > 0) {
        avgScreenTime += device['screenTimeMinutes'];
        validScreenTimeCount++;
      }

      String osInfo =
          '${device['os'] ?? 'Desconhecido'} ${device['osVersion'] ?? ''}'
              .trim();
      if (osInfo.isEmpty) osInfo = 'Desconhecido';
      osVersions[osInfo] = (osVersions[osInfo] ?? 0) + 1;

      String brand = device['brand'] ?? 'Desconhecida';
      brands[brand] = (brands[brand] ?? 0) + 1;
    }

    if (validScreenTimeCount > 0) {
      avgScreenTime = avgScreenTime / validScreenTimeCount;
    }

    int totalUsers = usersData.length;
    int adminUsers = usersData.where((u) => u['isAdmin'] == true).length;
    int regularUsers = totalUsers - adminUsers;

    return {
      'totalDevices': totalDevices,
      'onlineDevices': onlineDevices,
      'offlineDevices': offlineDevices,
      'avgScreenTime': avgScreenTime,
      'osVersions': osVersions,
      'brands': brands,
      'totalUsers': totalUsers,
      'adminUsers': adminUsers,
      'regularUsers': regularUsers,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading ? _buildLoadingState() : _buildDashboardContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'Carregando dados do dashboard...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: primaryColor,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: primaryColor),
                        onPressed: _loadDashboardData,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Visão geral do sistema CorpSync',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: _buildStatsCards()),
          SliverToBoxAdapter(child: _buildChartsSection()),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total de Dispositivos',
                  _dashboardData['totalDevices']?.toString() ?? '0',
                  Icons.devices,
                  primaryColor,
                  'dispositivos registrados',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Online',
                  _dashboardData['onlineDevices']?.toString() ?? '0',
                  Icons.wifi,
                  Colors.green,
                  'dispositivos conectados',
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Offline',
                  _dashboardData['offlineDevices']?.toString() ?? '0',
                  Icons.wifi_off,
                  Colors.red,
                  'dispositivos desconectados',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Tempo Médio de Tela',
                  '${(_dashboardData['avgScreenTime'] ?? 0).toStringAsFixed(0)}min',
                  Icons.access_time,
                  lightGreenColor,
                  'por dispositivo',
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total de Usuários',
                  _dashboardData['totalUsers']?.toString() ?? '0',
                  Icons.group,
                  primaryColor,
                  'usuários cadastrados',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Administradores',
                  _dashboardData['adminUsers']?.toString() ?? '0',
                  Icons.admin_panel_settings,
                  orangeColor,
                  'usuários admin',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Análises',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 20),
          _buildOnlineOfflineChart(),
          SizedBox(height: 24),
          _buildOSVersionChart(),
          SizedBox(height: 24),
          _buildBrandChart(),
          SizedBox(height: 24),
          _buildUserChart(),
        ],
      ),
    );
  }

  Widget _buildOnlineOfflineChart() {
    final List<ChartData> chartData = [
      ChartData(
        'Online',
        _dashboardData['onlineDevices']?.toDouble() ?? 0,
        Colors.green,
      ),
      ChartData(
        'Offline',
        _dashboardData['offlineDevices']?.toDouble() ?? 0,
        Colors.red,
      ),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status dos Dispositivos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                ),
                series: <CircularSeries>[
                  DoughnutSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.category,
                    yValueMapper: (ChartData data, _) => data.value,
                    pointColorMapper: (ChartData data, _) => data.color,
                    innerRadius: '60%',
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOSVersionChart() {
    final osVersions = _dashboardData['osVersions'] as Map<String, int>? ?? {};

    final sortedEntries =
        osVersions.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final totalItems = sortedEntries.length;
    final totalPages = (totalItems / _osVersionItemsPerPage).ceil();
    final startIndex = _osVersionCurrentPage * _osVersionItemsPerPage;
    final endIndex =
        (startIndex + _osVersionItemsPerPage < totalItems)
            ? startIndex + _osVersionItemsPerPage
            : totalItems;

    final paginatedEntries =
        startIndex < totalItems
            ? sortedEntries.sublist(startIndex, endIndex)
            : <MapEntry<String, int>>[];
    final List<ChartData> chartData = [];
    final colors = [
      primaryColor,
      darkBlueColor,
      lightGreenColor,
      paleGreenColor,
      yellowGreenColor,
      orangeColor,
    ];

    for (int i = 0; i < paginatedEntries.length; i++) {
      final entry = paginatedEntries[i];
      chartData.add(
        ChartData(entry.key, entry.value.toDouble(), colors[i % colors.length]),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        height: 450,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dispositivos por Versão do OS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child:
                  chartData.isEmpty
                      ? Center(
                        child: Text(
                          'Nenhum dado disponível',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                      : SfCartesianChart(
                        primaryXAxis: CategoryAxis(
                          labelStyle: TextStyle(fontSize: 10),
                          labelRotation: -45,
                        ),
                        primaryYAxis: NumericAxis(),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CartesianSeries>[
                          ColumnSeries<ChartData, String>(
                            dataSource: chartData,
                            xValueMapper: (ChartData data, _) => data.category,
                            yValueMapper: (ChartData data, _) => data.value,
                            pointColorMapper: (ChartData data, _) => data.color,
                            borderRadius: BorderRadius.circular(4),
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              textStyle: TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
            ),
            if (totalPages > 1) ...[
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        _osVersionCurrentPage > 0
                            ? () {
                              setState(() {
                                _osVersionCurrentPage--;
                              });
                            }
                            : null,
                    icon: Icon(Icons.arrow_back, size: 16),
                    label: Text('Anterior'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_osVersionCurrentPage + 1} / $totalPages',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed:
                        _osVersionCurrentPage < totalPages - 1
                            ? () {
                              setState(() {
                                _osVersionCurrentPage++;
                              });
                            }
                            : null,
                    icon: Icon(Icons.arrow_forward, size: 16),
                    label: Text('Próximo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  'Exibindo ${paginatedEntries.length} de $totalItems versões (ordenado por quantidade decrescente)',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBrandChart() {
    final brands = _dashboardData['brands'] as Map<String, int>? ?? {};
    final List<ChartData> chartData = [];
    final colors = [
      primaryColor,
      darkBlueColor,
      lightGreenColor,
      paleGreenColor,
      yellowGreenColor,
      orangeColor,
    ];

    int colorIndex = 0;
    brands.forEach((brand, count) {
      chartData.add(
        ChartData(brand, count.toDouble(), colors[colorIndex % colors.length]),
      );
      colorIndex++;
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dispositivos por Marca',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child:
                  chartData.isEmpty
                      ? Center(
                        child: Text(
                          'Nenhum dado disponível',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                      : SfCircularChart(
                        legend: Legend(
                          isVisible: true,
                          position: LegendPosition.right,
                          overflowMode: LegendItemOverflowMode.wrap,
                        ),
                        series: <CircularSeries>[
                          PieSeries<ChartData, String>(
                            dataSource: chartData,
                            xValueMapper: (ChartData data, _) => data.category,
                            yValueMapper: (ChartData data, _) => data.value,
                            pointColorMapper: (ChartData data, _) => data.color,
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              labelPosition: ChartDataLabelPosition.outside,
                            ),
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserChart() {
    final List<ChartData> chartData = [
      ChartData(
        'Usuários Regulares',
        _dashboardData['regularUsers']?.toDouble() ?? 0,
        primaryColor,
      ),
      ChartData(
        'Administradores',
        _dashboardData['adminUsers']?.toDouble() ?? 0,
        orangeColor,
      ),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribuição de Usuários',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                ),
                series: <CircularSeries>[
                  DoughnutSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.category,
                    yValueMapper: (ChartData data, _) => data.value,
                    pointColorMapper: (ChartData data, _) => data.color,
                    innerRadius: '60%',
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  final String category;
  final double value;
  final Color color;

  ChartData(this.category, this.value, this.color);
}
