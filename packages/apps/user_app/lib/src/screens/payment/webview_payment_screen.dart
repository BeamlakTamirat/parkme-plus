import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared/shared.dart';
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
  ConsumerState<WebViewPaymentScreen> createState() =>
      _WebViewPaymentScreenState();
}

class _WebViewPaymentScreenState extends ConsumerState<WebViewPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _paymentStatus =
      'waiting'; // waiting, success_detected, failure_detected

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    try {
      if (kDebugMode) {
        print('🌐 Initializing WebView for URL: ${widget.checkoutUrl}');
        print('🔑 Transaction Reference: ${widget.txRef}');
      }

      // Validate URL before loading
      final uri = Uri.tryParse(widget.checkoutUrl);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        if (kDebugMode) {
          print('❌ Invalid URL format: ${widget.checkoutUrl}');
        }
        setState(() {
          _hasError = true;
          _errorMessage = 'Invalid payment URL format';
        });
        return;
      }

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent('ParkMe+-Mobile-App/1.0 (Flutter; Android)')
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
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
              }
            },
            onPageFinished: (String url) {
              if (kDebugMode) {
                print('🌐 Page finished loading: $url');
              }
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }

              // Check if we've reached a success/failure page
              _checkPaymentStatus(url);
            },
            onWebResourceError: (WebResourceError error) {
              if (kDebugMode) {
                print('❌ WebView error: ${error.description}');
                print('🔍 Error type: ${error.errorType}');
                print('🔍 Error code: ${error.errorCode}');
              }

              // Handle connection errors gracefully
              if (error.description.contains('ERR_CONNECTION_REFUSED') ||
                  error.description.contains('ERR_NAME_NOT_RESOLVED') ||
                  error.description.contains('ERR_INTERNET_DISCONNECTED')) {
                if (kDebugMode) {
                  print('🌐 Connection error detected - likely network issue');
                }
                // Don't show error for network connection issues immediately
                return;
              }

              // Only show critical errors that prevent payment
              if (error.errorType == WebResourceErrorType.hostLookup ||
                  error.errorType == WebResourceErrorType.timeout) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _hasError = true;
                    _errorMessage = 'Network error: ${error.description}';
                  });
                }
              }
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
        );

      // Load the checkout URL
      _controller.loadRequest(Uri.parse(widget.checkoutUrl));

      if (kDebugMode) {
        print('✅ WebView initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ WebView initialization error: $e');
      }
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize payment page: $e';
        });
      }
    }
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
        print(
            '✅ Payment success/receipt page detected - WAITING for user confirmation');
      }
      setState(() {
        _paymentStatus = 'success_detected';
      });
      // DO NOT auto-close - let user click "I Completed Payment"
    } else if (url.contains('failure') ||
        url.contains('failed') ||
        url.contains('error')) {
      if (kDebugMode) {
        print(
            '❌ Payment failure page detected - WAITING for user confirmation');
      }
      setState(() {
        _paymentStatus = 'failure_detected';
      });
      // DO NOT auto-close - let user decide
    } else if (url.contains('cancel') || url.contains('cancelled')) {
      if (kDebugMode) {
        print(
            '🚫 Payment cancellation page detected - WAITING for user confirmation');
      }
      setState(() {
        _paymentStatus = 'failure_detected';
      });
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

  void _showSecurePaymentVerification() {
    if (kDebugMode) {
      print('🔒 Starting secure payment verification...');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated security icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Verifying Payment',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'Please wait while we securely verify your payment with Chapa',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Animated progress indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
                        backgroundColor: Colors.orange[100],
                      ),
                    ),
                    Icon(
                      Icons.lock_clock,
                      color: Colors.orange[600],
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Transaction reference
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Transaction ID',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.txRef,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[800],
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Status indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatusDot(true),
                    _buildStatusLine(),
                    _buildStatusDot(false),
                    _buildStatusLine(),
                    _buildStatusDot(false),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Step 1 of 3: Verifying transaction...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),

                // Cancel button
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _handlePaymentFailure('Payment verification cancelled');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'Cancel Verification',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Start actual payment verification
    _verifyPaymentWithChapa();
  }

  Widget _buildStatusDot(bool isActive) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.orange[600] : Colors.grey[300],
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildStatusLine() {
    return Container(
      width: 24,
      height: 2,
      color: Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Future<void> _verifyPaymentWithChapa() async {
    try {
      if (kDebugMode) {
        print('🔍 Verifying payment with Chapa API...');
        print('   Transaction Ref: ${widget.txRef}');
      }

      // Call Chapa verification API
      final verificationResult = await _callChapaVerificationAPI();

      if (mounted) {
        Navigator.of(context).pop(); // Close verification dialog

        if (verificationResult['success'] == true) {
          if (kDebugMode) {
            print('✅ Payment verified successfully with Chapa');
            print('   Status: ${verificationResult['status']}');
            print('   Amount: ${verificationResult['amount']}');
          }
          _handlePaymentSuccess();
        } else {
          if (kDebugMode) {
            print('❌ Payment verification failed');
            print('   Reason: ${verificationResult['message']}');
          }
          _handlePaymentFailure(
              verificationResult['message'] ?? 'Payment verification failed');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Payment verification error: $e');
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close verification dialog
        _handlePaymentFailure('Payment verification failed: $e');
      }
    }
  }

  Future<Map<String, dynamic>> _callChapaVerificationAPI() async {
    try {
      // Use the singleton instance of payment service
      final paymentService = ChapaPaymentService.instance;

      // Get expected amount and currency from payment data for security validation
      final expectedAmount = widget.paymentData['amount'] as double?;
      const expectedCurrency = 'ETB'; // Ethiopian Birr

      if (kDebugMode) {
        print('🔒 Calling Chapa verification with security checks:');
        print('   Transaction: ${widget.txRef}');
        print('   Expected Amount: $expectedAmount ETB');
      }

      // Call Chapa verification API with security validations
      final result = await paymentService.verifyPayment(
        txRef: widget.txRef,
        expectedAmount: expectedAmount,
        expectedCurrency: expectedCurrency,
      );

      return {
        'success': result.success,
        'status': result.status,
        'amount': result.amount,
        'message': result.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Verification API call failed: $e',
      };
    }
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
            icon: const Icon(Icons.security, color: Colors.blue),
            tooltip: 'Verify Payment',
            onPressed: _showSecurePaymentVerification,
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
              color: Colors.white.withValues(alpha: 0.8),
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
                              ? '✅ Payment completed successfully! Click "Verify Payment" to continue.'
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
                      onPressed: _showSecurePaymentVerification,
                      icon: const Icon(Icons.security),
                      label: const Text('Verify Payment'),
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
                    onPressed: () =>
                        _handlePaymentFailure('Payment cancelled by user'),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
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
        if (mounted) {
          Navigator.of(context).pop();
          _showReceiptErrorDialog(
              'Storage permission required to save receipt');
        }
        return;
      }

      // Get the current URL to save receipt information
      final currentUrl = await _controller.currentUrl();
      if (currentUrl == null) {
        if (mounted) {
          Navigator.of(context).pop();
          _showReceiptErrorDialog('Failed to get receipt information');
        }
        return;
      }

      // Create a text-based receipt file with the transaction details
      final receiptContent = _generateReceiptContent(currentUrl);
      final filePath = await _saveReceiptTextToDevice(receiptContent);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (filePath != null) {
        _showReceiptSavedDialog(filePath);
      } else {
        _showReceiptErrorDialog('Failed to save receipt to device');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
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
           ParkMe+ Smart Parking
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

      final fileName =
          'Chapa_Receipt_${widget.txRef}_${DateTime.now().millisecondsSinceEpoch}.txt';
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
