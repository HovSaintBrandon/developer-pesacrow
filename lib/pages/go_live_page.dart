import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_text.dart';
import '../services/api_service.dart';

class GoLivePage extends StatefulWidget {
  const GoLivePage({super.key});

  @override
  State<GoLivePage> createState() => _GoLivePageState();
}

class _GoLivePageState extends State<GoLivePage> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  // Auth state
  bool _isLoggedIn = false;
  bool _otpSent = false;
  bool _isLoading = false;
  
  // Controllers
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _platformPhoneController = TextEditingController();
  final _webhookController = TextEditingController();

  void _handleSendOtp() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.sendOtp(_phoneController.text);
      if (res['success']) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to your phone')),
        );
      } else {
        _showError(res['message']);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleVerifyOtp() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.verifyOtp(_phoneController.text, _otpController.text);
      if (res['success']) {
        setState(() => _isLoggedIn = true);
      } else {
        _showError(res['message']);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleSubmitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final res = await _api.requestGoLive(
        name: _nameController.text,
        email: _emailController.text,
        platformPhone: _platformPhoneController.text,
        webhookUrl: _webhookController.text.isEmpty ? null : _webhookController.text,
      );
      
      if (res['success']) {
        _showSuccess();
      } else {
        _showError(res['message']);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const GradientText('Request Submitted!', fontSize: 24, fontWeight: FontWeight.bold),
        content: const Text(
          'Your go-live request has been received. Our team will review your application and send your API credentials to the provided email address.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to docs
            },
            child: const Text('Back to Documentation', style: TextStyle(color: AppColors.cyan)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Go Live Request'),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: AppColors.cyberCard(),
            padding: const EdgeInsets.all(32),
            child: _isLoggedIn ? _buildRequestForm() : _buildAuthFlow(),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthFlow() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GradientText('Developer Identity', fontSize: 28, fontWeight: FontWeight.bold),
        const SizedBox(height: 8),
        const Text(
          'Verify your phone number to request production access.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _phoneController,
          enabled: !_otpSent,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Phone Number', '2547XXXXXXXX', Icons.phone),
          keyboardType: TextInputType.phone,
        ),
        if (_otpSent) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _otpController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Enter 6-digit OTP', '123456', Icons.lock_outline),
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : (_otpSent ? _handleVerifyOtp : _handleSendOtp),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(_otpSent ? 'VERIFY OTP' : 'SEND OTP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GradientText('Production Access', fontSize: 28, fontWeight: FontWeight.bold),
          const SizedBox(height: 8),
          const Text(
            'Tell us about your platform to generate your live credentials.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Platform Name', 'e.g. My Awesome Shop', Icons.business),
            validator: (v) => v!.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Technical Email', 'Where API keys will be sent', Icons.email_outlined),
            validator: (v) => v!.isEmpty ? 'Email is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _platformPhoneController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Settlement Phone', '2547XXXXXXXX', Icons.account_balance_wallet_outlined),
            validator: (v) => v!.isEmpty ? 'Phone is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _webhookController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Webhook URL (Optional)', 'https://api.myapp.com/webhook', Icons.webhook),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('SUBMIT GO-LIVE REQUEST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
      prefixIcon: Icon(icon, color: AppColors.cyan),
      filled: true,
      fillColor: Colors.white.withOpacity(0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cyan),
      ),
    );
  }
}
