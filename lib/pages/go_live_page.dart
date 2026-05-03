import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_text.dart';
import '../services/api_service.dart';

enum GoLiveStep {
  auth,
  kycType,
  manualKycStep1, // ID & Taxpayer type
  manualKycStep2, // Names
  manualKycStep3, // KRA PIN
  ocrKyc,
  platformDetails,
  success
}

class GoLivePage extends StatefulWidget {
  const GoLivePage({super.key});

  @override
  State<GoLivePage> createState() => _GoLivePageState();
}

class _GoLivePageState extends State<GoLivePage> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  GoLiveStep _currentStep = GoLiveStep.auth;
  bool _isLoading = false;
  bool _otpSent = false;

  // Controllers
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  // KYC Manual Controllers
  final _idNumberController = TextEditingController();
  final _taxpayerTypeController = TextEditingController(text: 'KE');
  final _namesController = TextEditingController();
  final _kraPinController = TextEditingController();
  
  // OCR Files
  PlatformFile? _idFront;
  PlatformFile? _kraPinImage;
  PlatformFile? _idBack;

  // Platform Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _platformPhoneController = TextEditingController();
  final _webhookController = TextEditingController();

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  // --- Auth Actions ---

  void _handleSendOtp() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.sendOtp(_phoneController.text);
      if (res['success']) {
        setState(() => _otpSent = true);
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
        setState(() => _currentStep = GoLiveStep.kycType);
      } else {
        _showError(res['message']);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- KYC Manual Actions ---

  void _handleManualStep1() async {
    if (_idNumberController.text.isEmpty) {
      _showError('ID Number is required');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await _api.checkId(_idNumberController.text, _taxpayerTypeController.text);
      if (res['success']) {
        setState(() => _currentStep = GoLiveStep.manualKycStep2);
      } else {
        _showError(res['message']);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleManualStep2() async {
    if (_namesController.text.isEmpty) {
      _showError('Names are required');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await _api.validateNames(_namesController.text);
      if (res['success']) {
        setState(() => _currentStep = GoLiveStep.manualKycStep3);
      } else {
        _showError(res['message']);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleManualStep3() async {
    if (_kraPinController.text.isEmpty) {
      _showError('KRA PIN is required');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await _api.validatePin(_kraPinController.text);
      if (res['success']) {
        setState(() => _currentStep = GoLiveStep.platformDetails);
      } else {
        _showError(res['message']);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- OCR Actions ---

  Future<void> _pickFile(String type) async {
    try {
      // In version 11.x, the methods are static directly on the FilePicker class.
      // Removed .platform to match the new API.
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true, 
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          if (type == 'idFront') _idFront = result.files.first;
          if (type == 'kraPin') _kraPinImage = result.files.first;
          if (type == 'idBack') _idBack = result.files.first;
        });
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  void _handleOcrUpload() async {
    if (_idFront == null || _kraPinImage == null) {
      _showError('Please upload both ID Front and KRA PIN Image');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await _api.ocrUpload(
        idFrontBytes: _idFront!.bytes!,
        idFrontName: _idFront!.name,
        kraPinBytes: _kraPinImage!.bytes!,
        kraPinName: _kraPinImage!.name,
        idBackBytes: _idBack?.bytes,
        idBackName: _idBack?.name,
      );
      if (res['success']) {
        setState(() => _currentStep = GoLiveStep.platformDetails);
      } else {
        _showError(res['message']);
        // Fallback to manual if OCR fails
        setState(() => _currentStep = GoLiveStep.manualKycStep1);
      }
    } catch (e) {
      _showError(e.toString());
      setState(() => _currentStep = GoLiveStep.manualKycStep1);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Final Submission ---

  void _handleSubmitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final res = await _api.requestGoLive(
        name: _nameController.text,
        email: _emailController.text,
        platformPhone: _platformPhoneController.text,
        webhookUrl: _webhookController.text,
      );
      
      if (res['success']) {
        setState(() => _currentStep = GoLiveStep.success);
      } else {
        _showError(res['message']);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Go Live Request'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == GoLiveStep.auth) {
              Navigator.pop(context);
            } else {
              // Allow going back steps
              setState(() {
                if (_currentStep == GoLiveStep.kycType) _currentStep = GoLiveStep.auth;
                else if (_currentStep == GoLiveStep.manualKycStep1 || _currentStep == GoLiveStep.ocrKyc) _currentStep = GoLiveStep.kycType;
                else if (_currentStep == GoLiveStep.manualKycStep2) _currentStep = GoLiveStep.manualKycStep1;
                else if (_currentStep == GoLiveStep.manualKycStep3) _currentStep = GoLiveStep.manualKycStep2;
                else if (_currentStep == GoLiveStep.platformDetails) _currentStep = GoLiveStep.kycType;
              });
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: AppColors.cyberCard(),
            padding: const EdgeInsets.all(32),
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case GoLiveStep.auth: return _buildAuthFlow();
      case GoLiveStep.kycType: return _buildKycSelection();
      case GoLiveStep.manualKycStep1: return _buildManualStep1();
      case GoLiveStep.manualKycStep2: return _buildManualStep2();
      case GoLiveStep.manualKycStep3: return _buildManualStep3();
      case GoLiveStep.ocrKyc: return _buildOcrKyc();
      case GoLiveStep.platformDetails: return _buildRequestForm();
      case GoLiveStep.success: return _buildSuccess();
    }
  }

  Widget _buildAuthFlow() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GradientText('Step 1: Identity', fontSize: 28, fontWeight: FontWeight.bold),
        const SizedBox(height: 8),
        const Text(
          'Verify your phone number to start the KYC process.',
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
        _actionButton(
          text: _otpSent ? 'VERIFY OTP' : 'SEND OTP',
          onPressed: _isLoading ? null : (_otpSent ? _handleVerifyOtp : _handleSendOtp),
          color: AppColors.brandGreen,
        ),
      ],
    );
  }

  Widget _buildKycSelection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GradientText('Step 2: KYC Type', fontSize: 28, fontWeight: FontWeight.bold),
        const SizedBox(height: 8),
        const Text(
          'Choose how you want to verify your identity.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 32),
        _selectionCard(
          title: 'Manual Entry',
          subtitle: 'Type your details manually (Reliable)',
          icon: Icons.edit_document,
          onTap: () => setState(() => _currentStep = GoLiveStep.manualKycStep1),
        ),
        const SizedBox(height: 16),
        _selectionCard(
          title: 'Scan Documents',
          subtitle: 'Upload images for AI extraction (Fast)',
          icon: Icons.document_scanner,
          onTap: () => setState(() => _currentStep = GoLiveStep.ocrKyc),
        ),
      ],
    );
  }

  Widget _buildManualStep1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GradientText('Manual KYC: Step 1', fontSize: 28, fontWeight: FontWeight.bold),
        const SizedBox(height: 8),
        const Text('Enter your ID number and taxpayer type.', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        TextField(
          controller: _idNumberController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('National ID Number', '12345678', Icons.badge_outlined),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _taxpayerTypeController.text,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Taxpayer Type', '', Icons.person_search),
          items: const [
            DropdownMenuItem(value: 'KE', child: Text('Individual (KE)')),
            DropdownMenuItem(value: 'CO', child: Text('Company (CO)')),
          ],
          onChanged: (v) => setState(() => _taxpayerTypeController.text = v!),
        ),
        const SizedBox(height: 32),
        _actionButton(text: 'CONTINUE', onPressed: _isLoading ? null : _handleManualStep1),
      ],
    );
  }

  Widget _buildManualStep2() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GradientText('Manual KYC: Step 2', fontSize: 28, fontWeight: FontWeight.bold),
        const SizedBox(height: 8),
        const Text('Enter names exactly as they appear on your ID.', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        TextField(
          controller: _namesController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Full Names', 'JOHN DOE', Icons.person_outline),
        ),
        const SizedBox(height: 32),
        _actionButton(text: 'VALIDATE NAMES', onPressed: _isLoading ? null : _handleManualStep2),
      ],
    );
  }

  Widget _buildManualStep3() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GradientText('Manual KYC: Step 3', fontSize: 28, fontWeight: FontWeight.bold),
        const SizedBox(height: 8),
        const Text('Enter your KRA PIN to complete verification.', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        TextField(
          controller: _kraPinController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('KRA PIN', 'A00...Z', Icons.pin),
        ),
        const SizedBox(height: 32),
        _actionButton(text: 'VALIDATE PIN', onPressed: _isLoading ? null : _handleManualStep3),
      ],
    );
  }

  Widget _buildOcrKyc() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GradientText('AI Scan Verification', fontSize: 28, fontWeight: FontWeight.bold),
        const SizedBox(height: 8),
        const Text('Upload your documents for automatic extraction.', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        _uploadSlot('National ID Front', _idFront, () => _pickFile('idFront')),
        const SizedBox(height: 16),
        _uploadSlot('KRA PIN Certificate', _kraPinImage, () => _pickFile('kraPin')),
        const SizedBox(height: 16),
        _uploadSlot('National ID Back (Optional)', _idBack, () => _pickFile('idBack')),
        const SizedBox(height: 32),
        if (_isLoading)
          const Center(child: Column(
            children: [
              CircularProgressIndicator(color: AppColors.cyan),
              SizedBox(height: 16),
              Text('Extracting data and verifying with KRA...', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ))
        else
          _actionButton(text: 'EXTRACT & VERIFY', onPressed: _handleOcrUpload),
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
          const GradientText('Final Step: Platform', fontSize: 28, fontWeight: FontWeight.bold),
          const SizedBox(height: 8),
          const Text('Almost there! Tell us about your platform.', style: TextStyle(color: AppColors.textSecondary)),
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
            decoration: _inputDecoration('Technical Email', 'For API keys', Icons.email_outlined),
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
            decoration: _inputDecoration('Web URL', 'https://...', Icons.webhook),
            validator: (v) => v!.isEmpty ? 'Web URL is required' : null,
          ),
          const SizedBox(height: 32),
          _actionButton(text: 'SUBMIT GO-LIVE REQUEST', onPressed: _isLoading ? null : _handleSubmitRequest, color: AppColors.brandBlue),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, color: AppColors.brandGreen, size: 80),
        const SizedBox(height: 24),
        const GradientText('Request Submitted!', fontSize: 28, fontWeight: FontWeight.bold),
        const SizedBox(height: 16),
        const Text(
          'Your go-live request has been received. Our team will review your application and send your API credentials to the provided email address.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 32),
        _actionButton(
          text: 'BACK TO DOCS', 
          onPressed: () {
            Navigator.pop(context);
          },
          color: AppColors.surface,
        ),
      ],
    );
  }

  // --- Helpers ---

  Widget _selectionCard({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.cyan, size: 32),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _uploadSlot(String label, PlatformFile? file, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: file == null ? Colors.white.withOpacity(0.1) : AppColors.brandGreen.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(file == null ? Icons.cloud_upload_outlined : Icons.check_circle, color: file == null ? AppColors.textMuted : AppColors.brandGreen),
            const SizedBox(width: 16),
            Expanded(child: Text(file == null ? label : file.name, style: TextStyle(color: file == null ? AppColors.textSecondary : Colors.white))),
            if (file != null) const Icon(Icons.edit, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({required String text, required VoidCallback? onPressed, Color? color}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.cyan,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
