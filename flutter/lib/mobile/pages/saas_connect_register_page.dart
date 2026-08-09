import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// SAAS Connect - account creation. Calls the SAAS Connect backend directly
/// (POST /api/register). New accounts start unapproved; the admin (SK)
/// approves them from SAAS Call's unified Approvals tab, exactly like SAAS
/// VPN/AI. This screen just shows that pending state back to the user.
class SaasConnectRegisterPage extends StatefulWidget {
  const SaasConnectRegisterPage({Key? key}) : super(key: key);

  @override
  State<SaasConnectRegisterPage> createState() => _SaasConnectRegisterPageState();
}

class _SaasConnectRegisterPageState extends State<SaasConnectRegisterPage> {
  static const String apiBase = 'https://connect.santhoshku.online';

  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _recoveryPinCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _pinCtrl.dispose();
    _recoveryPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
      _successMessage = null;
    });
    try {
      final resp = await http.post(
        Uri.parse('$apiBase/api/register'),
        body: {
          'name': _nameCtrl.text.trim(),
          'mobile': _mobileCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'pin': _pinCtrl.text.trim(),
          'recovery_pin': _recoveryPinCtrl.text.trim(),
        },
      ).timeout(const Duration(seconds: 20));
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode == 200) {
        setState(() {
          _successMessage = (data['message'] as String?) ??
              'Registration successful. Wait for admin approval before you can sign in.';
        });
        return;
      }
      setState(() => _error = (data['detail'] ?? 'Registration failed').toString());
    } catch (e) {
      setState(() => _error = 'Could not reach the server. Check your internet connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF7A59),
              Color(0xFFE85D9A),
              Color(0xFF16A6A6),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    const Text('Create Account',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_successMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 32),
                        const SizedBox(height: 8),
                        Text(_successMessage!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Sign In'),
                  ),
                ] else ...[
                  _field(_nameCtrl, 'Full Name', Icons.person_outline),
                  const SizedBox(height: 12),
                  _field(_mobileCtrl, 'Mobile Number', Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field(_emailCtrl, 'Email Address', Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _field(_pinCtrl, 'Login PIN (6 digits)', Icons.lock_outline_rounded,
                      keyboardType: TextInputType.number, obscure: true, maxLength: 6),
                  const SizedBox(height: 12),
                  _field(_recoveryPinCtrl, 'Recovery PIN (6 digits, different from login)',
                      Icons.shield_outlined,
                      keyboardType: TextInputType.number, obscure: true, maxLength: 6),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFE85D9A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : const Text('Create Account',
                              style:
                                  TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboardType, bool obscure = false, int? maxLength}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        obscureText: obscure,
        maxLength: maxLength,
        decoration: InputDecoration(
          border: InputBorder.none,
          counterText: '',
          icon: Icon(icon, color: Colors.black54),
          hintText: hint,
        ),
      ),
    );
  }
}
