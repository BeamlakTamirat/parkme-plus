class ChapaPayment {
  final String txRef;
  final double amount;
  final String currency;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String title;
  final String description;
  final String callbackUrl;
  final String returnUrl;

  const ChapaPayment({
    required this.txRef,
    required this.amount,
    required this.currency,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.title,
    required this.description,
    required this.callbackUrl,
    required this.returnUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'tx_ref': txRef,
      'amount': amount,
      'currency': currency,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      'title': title,
      'description': description,
      'callback_url': callbackUrl,
      'return_url': returnUrl,
    };
  }
} 