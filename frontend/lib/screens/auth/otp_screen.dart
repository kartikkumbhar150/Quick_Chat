import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String userId;
  final String email;

  const OtpScreen({super.key, required this.userId, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _ctrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  bool _resending = false;

  String get _otp => _ctrls.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter all 6 digits'), backgroundColor: AppTheme.error),
      );
      return;
    }
    setState(() => _loading = true);
    final res = await AuthService.verifyOtp(widget.userId, _otp);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Invalid OTP'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final res = await AuthService.resendOtp(widget.userId);
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message'] ?? 'OTP resent'),
        backgroundColor: res['success'] == true ? AppTheme.secondary : AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.mark_email_read_rounded, size: 44, color: AppTheme.primary),
              ),
              const SizedBox(height: 24),
              const Text('Verify Your Email', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'We sent a 6-digit code to\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 40),
              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _buildOtpBox(i)),
              ),
              const SizedBox(height: 40),
              _loading
                  ? const CircularProgressIndicator(color: AppTheme.primary)
                  : ElevatedButton(
                      onPressed: _verify,
                      child: const Text('Verify'),
                    ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive the code? ", style: TextStyle(color: AppTheme.textSecondary)),
                  _resending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton(
                          onPressed: _resend,
                          child: const Text('Resend', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: _ctrls[index],
        focusNode: _nodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
          fillColor: AppTheme.surfaceLight,
          filled: true,
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _nodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _nodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }
}
