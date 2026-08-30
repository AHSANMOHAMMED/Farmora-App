import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../services/firebase_service.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final _service = FirestoreService();
  bool _busy = false;

  Future<void> _verify(String? value) async {
    if (_busy || value == null) return;
    final parts = value.split('|');
    if (parts.length != 2 || parts.any((part) => part.isEmpty)) {
      _showError('This is not a Farmora authenticity code.');
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await _service.verifyProductBarcode(
        barcodeId: parts[0],
        signature: parts[1],
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (_) {
      if (mounted) {
        _showError('Barcode could not be verified or is not assigned to you.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify harvest')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: (capture) => _verify(
              capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue,
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: Card(
              color: Colors.black87,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Scan the Farmora code attached to your parcel. Verification is required before escrow can be released.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          if (_busy) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
