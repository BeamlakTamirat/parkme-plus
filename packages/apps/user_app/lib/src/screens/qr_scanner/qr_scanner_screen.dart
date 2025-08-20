import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  bool _isScanning = false;
  String _scannedCode = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'QR Scanner',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Scanner area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Scanner overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.orange, width: 3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: _isScanning
                            ? _buildScanningAnimation()
                            : _buildScanPrompt(),
                      ),
                    ),
                  ),

                  // Corner indicators
                  Positioned(
                    top: 20,
                    left: 20,
                    child: _buildCornerIndicator(Colors.orange),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: _buildCornerIndicator(Colors.orange),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: _buildCornerIndicator(Colors.orange),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: _buildCornerIndicator(Colors.orange),
                  ),
                ],
              ),
            ),
          ),

          // Control buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_scannedCode.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Scanned: $_scannedCode',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isScanning ? _stopScanning : _startScanning,
                      icon: Icon(_isScanning ? Icons.stop : Icons.play_arrow),
                      label: Text(_isScanning ? 'Stop' : 'Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isScanning ? Colors.red : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _clearScan,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'How to use:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. Point your camera at a QR code\n'
                        '2. Hold steady until the code is scanned\n'
                        '3. The scanned data will appear below',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningAnimation() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withOpacity(0.3),
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.3),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              color: Colors.orange,
              size: 48,
            ),
            SizedBox(height: 8),
            Text(
              'Scanning...',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanPrompt() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.withOpacity(0.1),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              color: Colors.grey,
              size: 48,
            ),
            SizedBox(height: 8),
            Text(
              'Ready to scan',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerIndicator(Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
    });

    // Simulate scanning
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isScanning) {
        setState(() {
          _isScanning = false;
          _scannedCode = 'PARKING_QR_${DateTime.now().millisecondsSinceEpoch}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR Code scanned: $_scannedCode'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
  }

  void _clearScan() {
    setState(() {
      _scannedCode = '';
      _isScanning = false;
    });
  }
}
