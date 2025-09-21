import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../widgets/common/wepark_dialog.dart';

class WebViewPaymentScreen extends ConsumerStatefulWidget {
  final String checkoutUrl;
  final String txRef;
  final Map<String, dynamic> paymentData;
  final Function(bool success, String message) onPaymentComplete;

  const WebViewPaymentScreen({
    super.key,
    required this.checkoutUrl,
    required this.txRef,
    required this.paymentData,
    required this.onPaymentComplete,
  });

  @override
  ConsumerState<WebViewPaymentScreen> createState() => _WebViewPaymentScreenState();
}

class _WebViewPaymentScreenState extends ConsumerState<WebViewPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _paymentStatus = 'waiting'; // waiting, success_detected, failure_detected

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (kDebugMode) {
              print('🌐 WebView loading progress: $progress%');
            }
          },
          onPageStarted: (String url) {
            if (kDebugMode) {
              print('🌐 Page started loading: $url');
            }
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            if (kDebugMode) {
              print('🌐 Page finished loading: $url');
            }
            setState(() {
              _isLoading = false;
            });
            
            // Check if we've reached a success/failure page
            _checkPaymentStatus(url);
          },
          onWebResourceError: (WebResourceError error) {
            if (kDebugMode) {
              print('❌ WebView error: ${error.description}');
            }
            
            // Handle connection errors gracefully
            if (error.description.contains('ERR_CONNECTION_REFUSED') ||
                error.description.contains('ERR_NAME_NOT_RESOLVED')) {
              if (kDebugMode) {
                print('🌐 Connection error detected - likely webhook URL issue');
              }
              // Don't show error for webhook connection issues
              return;
            }
            
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = error.description;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            if (kDebugMode) {
              print('🌐 Navigation request: ${request.url}');
            }
            
            // Check if navigation is to success/failure URLs
            _checkPaymentStatus(request.url);
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _checkPaymentStatus(String url) {
    if (kDebugMode) {
      print('🔍 Checking payment status for URL: $url');
    }

    // ONLY LOG the status - DO NOT auto-close the WebView
    // Let the user manually confirm payment completion
    if (url.contains('success') || 
        url.contains('completed') || 
        url.contains('approved') ||
        url.contains('payment_success') ||
        url.contains('transaction_success') ||
        url.contains('chapa.co') && url.contains('receipt')) {
      if (kDebugMode) {
        print('✅ Payment success/receipt page detected - WAITING for user confirmation');
      }
      setState(() {
        _paymentStatus = 'success_detected';
      });
      // DO NOT auto-close - let user click "I Completed Payment"
    }
    else if (url.contains('failure') || 
             url.contains('failed') || 
             url.contains('error')) {
      if (kDebugMode) {
        print('❌ Payment failure page detected - WAITING for user confirmation');
      }
      setState(() {
        _paymentStatus = 'failure_detected';
      });
      // DO NOT auto-close - let user decide
    }
    else if (url.contains('cancel') || 
             url.contains('cancelled')) {
      if (kDebugMode) {
        print('🚫 Payment cancellation page detected - WAITING for user confirmation');
      }
      setState(() {
        _paymentStatus = 'failure_detected';
      });
      // DO NOT auto-close - let user decide
    }
  }

  void _handlePaymentSuccess() {
    if (kDebugMode) {
      print('🎉 Payment completed successfully!');
    }
    
    Navigator.of(context).pop();
    widget.onPaymentComplete(true, 'Payment completed successfully');
  }

  void _handlePaymentFailure(String message) {
    if (kDebugMode) {
      print('❌ Payment failed: $message');
    }
    
    Navigator.of(context).pop();
    widget.onPaymentComplete(false, message);
  }

  void _showManualConfirmationDialog() {
    if (kDebugMode) {
      print('🔍 Showing manual confirmation dialog...');
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        if (kDebugMode) {
          print('🔍 Dialog builder called');
        }
        
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Payment Status'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.payment,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                _paymentStatus == 'success_detected' 
                    ? 'Payment success detected! Confirm to proceed with booking.'
                    : 'Did you complete the payment successfully?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              
            ],
          ),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (kDebugMode) {
                        print('🔍 Yes, Completed button pressed');
                      }
                      Navigator.of(dialogContext).pop();
                      _handlePaymentSuccess();
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Yes, Completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (kDebugMode) {
                        print('🔍 No, Failed button pressed');
                      }
                      Navigator.of(dialogContext).pop();
                      _handlePaymentFailure('Payment not completed');
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('No, Failed'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Complete Payment',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () {
            _showExitConfirmationDialog();
          },
        ),
        actions: [
          // Download Chapa Receipt Button
          if (_paymentStatus == 'success_detected')
            IconButton(
              icon: const Icon(Icons.download, color: Colors.green),
              tooltip: 'Download Chapa Receipt',
              onPressed: _downloadChapaReceipt,
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              _controller.reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black87),
            onPressed: _showManualConfirmationDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load payment page',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                      });
                      _controller.reload();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            WebViewWidget(controller: _controller),
          
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading payment page...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Payment status indicator
              if (_paymentStatus != 'waiting')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _paymentStatus == 'success_detected' 
                        ? Colors.green[50] 
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _paymentStatus == 'success_detected' 
                          ? Colors.green 
                          : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _paymentStatus == 'success_detected' 
                            ? Icons.check_circle_outline 
                            : Icons.error_outline,
                        color: _paymentStatus == 'success_detected' 
                            ? Colors.green 
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _paymentStatus == 'success_detected'
                              ? '✅ Payment completed successfully! Click "I Completed Payment" to continue.'
                              : '❌ Payment issue detected. Please check and try again.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _paymentStatus == 'success_detected' 
                                ? Colors.green[800] 
                                : Colors.red[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showManualConfirmationDialog,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('I Completed Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _handlePaymentFailure('Payment cancelled by user'),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text('Are you sure you want to cancel this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No, Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handlePaymentFailure('Payment cancelled by user');
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadChapaReceipt() async {
    try {
      if (kDebugMode) {
        print('📄 Downloading Chapa receipt...');
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Downloading receipt...'),
            ],
          ),
        ),
      );

      // Request storage permission (different approach for Android 13+)
      bool hasPermission = false;
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), we don't need storage permission for Downloads
        hasPermission = true;
      } else {
        final permission = await Permission.storage.request();
        hasPermission = permission.isGranted;
      }
      
      if (!hasPermission) {
        Navigator.of(context).pop();
        _showReceiptErrorDialog('Storage permission required to save receipt');
        return;
      }

      // Get the current URL to save receipt information
      final currentUrl = await _controller.currentUrl();
      if (currentUrl == null) {
        Navigator.of(context).pop();
        _showReceiptErrorDialog('Failed to get receipt information');
        return;
      }

      // Create a text-based receipt file with the transaction details
      final receiptContent = _generateReceiptContent(currentUrl);
      final filePath = await _saveReceiptTextToDevice(receiptContent);
      
      // Close loading dialog
      Navigator.of(context).pop();

      if (filePath != null) {
        _showReceiptSavedDialog(filePath);
      } else {
        _showReceiptErrorDialog('Failed to save receipt to device');
      }
    } catch (e) {
      Navigator.of(context).pop();
      if (kDebugMode) print('❌ Receipt download error: $e');
      _showReceiptErrorDialog('Failed to download receipt: $e');
    }
  }

  String _generateReceiptContent(String currentUrl) {
    final now = DateTime.now();
    return '''
═══════════════════════════════════════
           CHAPA PAYMENT RECEIPT
═══════════════════════════════════════

Transaction ID: ${widget.txRef}
Date: ${now.toString().split('.')[0]}
Status: Payment Completed Successfully

Payment Details:
• Amount: ${widget.paymentData['amount']} ETB
• Payment Method: ${widget.paymentData['paymentMethod'] ?? 'Mobile Payment'}
• Customer Email: ${widget.paymentData['userEmail'] ?? 'N/A'}
• Customer Name: ${widget.paymentData['userName'] ?? 'N/A'}

Booking Information:
• Booking ID: ${widget.paymentData['bookingId'] ?? 'N/A'}
• Location: ${widget.paymentData['parkingLocationName'] ?? 'N/A'}
• Vehicle Plate: ${widget.paymentData['vehiclePlateNumber'] ?? 'N/A'}

Receipt URL: $currentUrl

═══════════════════════════════════════
           WePark Smart Parking
           Addis Ababa, Ethiopia
           Thank you for your payment!
═══════════════════════════════════════

Generated: ${now.toString()}
''';
  }

  Future<String?> _saveReceiptTextToDevice(String receiptContent) async {
    try {
      // Get Downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        if (kDebugMode) print('❌ Could not get storage directory');
        return null;
      }

      final fileName = 'Chapa_Receipt_${widget.txRef}_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(receiptContent);
      
      if (kDebugMode) print('✅ Chapa receipt saved to: ${file.path}');
      return file.path;
    } catch (e) {
      if (kDebugMode) print('❌ Error saving receipt: $e');
      return null;
    }
  }

  void _showReceiptSavedDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => WeParkDialog(
        title: 'Receipt Downloaded!',
        titleIcon: Icons.download_done,
        titleIconColor: Colors.green,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 48,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chapa receipt details have been saved to your device!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                'Saved to: ${filePath.split('/').last}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Check your Downloads folder or Files app to view the receipt text file.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF1565C0)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          WeParkButton(
            text: 'OK',
            icon: Icons.check,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showReceiptErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => WeParkDialog(
        title: 'Download Failed',
        titleIcon: Icons.error_outline,
        titleIconColor: Colors.red,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          WeParkButton(
            text: 'OK',
            icon: Icons.check,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
