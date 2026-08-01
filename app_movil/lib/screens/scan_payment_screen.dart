import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ScanPaymentScreen extends StatefulWidget {
  const ScanPaymentScreen({super.key});

  @override
  _ScanPaymentScreenState createState() => _ScanPaymentScreenState();
}

class _ScanPaymentScreenState extends State<ScanPaymentScreen> {
  // QR
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _qrController;
  bool _isQrScanning = false;

  // NFC
  bool _isNfcReading = false;

  // Datos de la transacción
  Map<String, dynamic>? _transactionData;
  bool _isProcessing = false;

  @override
  void dispose() {
    _qrController?.dispose();
    super.dispose();
  }

  // ===================== QR =====================
  void _onQRViewCreated(QRViewController controller) {
    _qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      if (_isQrScanning || _transactionData != null) return;
      _isQrScanning = true;
      _procesarDatos(scanData.code);
    });
  }

  // ===================== NFC (CORREGIDO) =====================
  Future<void> _leerNFC() async {
    if (_isNfcReading || _transactionData != null) return;

    setState(() {
      _isNfcReading = true;
    });

    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NFC no disponible en este dispositivo')),
        );
        setState(() => _isNfcReading = false);
        return;
      }

      // 1. Detectar el tag con poll()
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 10),
        iosAlertMessage: 'Acerca tu iPhone al tag',
      );

      // 2. Verificar que el tag soporta NDEF
      if (tag.ndefAvailable != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este tag no soporta NDEF')),
        );
        await FlutterNfcKit.finish();
        setState(() => _isNfcReading = false);
        return;
      }

      // 3. Leer los registros NDEF
      final records = await FlutterNfcKit.readNDEFRecords();
      if (records.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tag sin datos')),
        );
        await FlutterNfcKit.finish();
        setState(() => _isNfcReading = false);
        return;
      }

      final record = records.first;
      String data;

      // Detectar si es UriRecord (del paquete ndef)
      if (record is ndef.UriRecord) {
        data = record.uri.toString();
      } else {
        // Intentar decodificar como texto
        try {
          data = String.fromCharCodes(record.payload!);
        } catch (_) {
          data = record.payload.toString();
        }
      }

      await FlutterNfcKit.finish();
      _procesarDatos(data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al leer NFC: $e')),
      );
      await FlutterNfcKit.finish().catchError((_) {});
    } finally {
      setState(() => _isNfcReading = false);
    }
  }

  // ===================== PROCESAR DATOS =====================
  void _procesarDatos(String? data) async {
    if (data == null) {
      setState(() => _isQrScanning = false);
      return;
    }

    try {
      String jsonString = data;
      if (data.startsWith('http')) {
        final uri = Uri.parse(data);
        final base64Data = uri.queryParameters['data'];
        if (base64Data != null) {
          final decoded = base64Decode(base64Data);
          jsonString = utf8.decode(decoded);
        }
      }

      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      setState(() {
        _transactionData = jsonData;
        _isQrScanning = false;
      });

      _mostrarDialogoPago();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar el código: $e')),
      );
      setState(() => _isQrScanning = false);
    }
  }

  // ===================== DIÁLOGO DE PAGO =====================
  void _mostrarDialogoPago() {
    if (_transactionData == null) return;

    final total = _transactionData!['total'] ?? 0.0;
    final lineas = _transactionData!['lineas'] as List<dynamic>?;
    final negocioId = _transactionData!['negocio_id'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Importe total: ${total.toStringAsFixed(2)} €'),
            const SizedBox(height: 8),
            if (lineas != null && lineas.isNotEmpty) ...[
              const Text('Concepto:'),
              ...lineas.map((l) => Text('  • ${l['descripcion']} x${l['cantidad']}')),
            ],
            const SizedBox(height: 16),
            const Text('Pagas como: Persona física (por ahora)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _transactionData = null);
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _confirmarPago(context, negocioId),
            child: const Text('Pagar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarPago(BuildContext dialogContext, int negocioId) async {
    if (_transactionData == null) return;

    setState(() => _isProcessing = true);
    Navigator.pop(dialogContext);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = Provider.of<ApiService>(context, listen: false);

      final pagadorId = await auth.obtenerToken();
      if (pagadorId == null) {
        throw Exception('Usuario no autenticado');
      }

      final total = _transactionData!['total'];
      final clienteId = _transactionData!['cliente_id'];

      if (int.parse(pagadorId) != clienteId) {
        throw Exception('Este código QR no es para ti (cliente incorrecto)');
      }

      await api.transferir(int.parse(pagadorId), negocioId, total);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Pago de ${total.toStringAsFixed(2)} € realizado')),
      );

      setState(() {
        _transactionData = null;
        _isProcessing = false;
      });

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al procesar el pago: $e')),
      );
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar con QR/NFC'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _transactionData == null
                ? QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    overlay: QrScannerOverlayShape(
                      borderColor: Colors.deepPurple,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: 250,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 80, color: Colors.green),
                        const SizedBox(height: 16),
                        Text(
                          'Código leído correctamente',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isNfcReading ? null : _leerNFC,
                  icon: const Icon(Icons.nfc),
                  label: Text(_isNfcReading ? 'Leyendo...' : 'Leer NFC'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (_isProcessing)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}