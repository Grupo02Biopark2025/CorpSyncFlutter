import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/workmanager_sync.dart';

class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  String scannedData = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scanQRCode();
    });
  }

  Future<void> scanQRCode() async {
    String qrResult = await FlutterBarcodeScanner.scanBarcode(
      '#ff6666',
      'Cancelar',
      true,
      ScanMode.QR,
    );

    if (qrResult != '-1') {
      setState(() {
        scannedData = qrResult;
      });

      await startPeriodicSyncAfterQRScan();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sincronização em segundo plano iniciada'),
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      _closeApp();
    }
  }

  void _closeApp() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escanear QR Code")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              scannedData.isEmpty ? "Aguardando leitura..." : "Escaneado com sucesso!",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
