import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/mobile/pages/home_page.dart';
import 'package:flutter_hbb/mobile/pages/saas_connect_register_page.dart';

/// SAAS Connect - custom mobile login screen.
///
/// Talks to the SAAS Connect backend (connect.santhoshku.online), NOT
/// RustDesk's own account system. On success it stores the session token via
/// RustDesk's existing local-option storage (same 'access_token' key/pattern
/// already used elsewhere in this codebase) and hands off to the normal
/// HomePage so remote-control/file-transfer/etc keep working unchanged.
class SaasConnectLoginPage extends StatefulWidget {
  const SaasConnectLoginPage({Key? key}) : super(key: key);

  @override
  State<SaasConnectLoginPage> createState() => _SaasConnectLoginPageState();
}

class _SaasConnectLoginPageState extends State<SaasConnectLoginPage> {
  static const String apiBase = 'https://connect.santhoshku.online';
  static const String logoUrl = '$apiBase/assets/logo.png';

  final _mobileCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _obscurePin = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final mobile = _mobileCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (mobile.isEmpty || pin.isEmpty) {
      setState(() => _error = 'Enter your mobile number and PIN');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await http.post(
        Uri.parse('$apiBase/api/login'),
        body: {'mobile': mobile, 'pin': pin},
      ).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token == null) {
          setState(() => _error = 'Unexpected server response');
          return;
        }
        await bind.mainSetLocalOption(key: 'access_token', value: token);
        final me = data['me'] as Map<String, dynamic>?;
        if (me != null) {
          await bind.mainSetLocalOption(
              key: 'saas_connect_name', value: '${me['name'] ?? ''}');
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage()),
        );
        return;
      }
      String message = 'Sign in failed';
      try {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        message = (data['detail'] ?? message).toString();
      } catch (_) {}
      setState(() => _error = message);
    } catch (e) {
      setState(() => _error = 'Could not reach the server. Check your internet connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _comingSoon(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what — coming soon')),
    );
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.network(
                      logoUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(Icons.hub_rounded,
                            color: Colors.white, size: 56),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SAAS\nCONNECT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sign in to continue to your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 28),
                _card(
                  child: TextField(
                    controller: _mobileCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      icon: Icon(Icons.phone_android_rounded, color: Colors.black54),
                      hintText: 'Mobile Number',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  child: TextField(
                    controller: _pinCtrl,
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      icon: const Icon(Icons.lock_outline_rounded, color: Colors.black54),
                      hintText: 'Login PIN',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePin ? Icons.visibility_off : Icons.visibility,
                          color: Colors.black45,
                        ),
                        onPressed: () => setState(() => _obscurePin = !_obscurePin),
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _comingSoon('Forgot PIN'),
                    child: const Text('Forgot PIN?', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signIn,
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
                        : const Text('Sign In',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: const [
                    Expanded(child: Divider(color: Colors.white54)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('or continue with', style: TextStyle(color: Colors.white70)),
                    ),
                    Expanded(child: Divider(color: Colors.white54)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _socialButton('Google', Icons.g_mobiledata_rounded,
                          () => _comingSoon('Google sign-in')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _socialButton('Microsoft', Icons.window_rounded,
                          () => _comingSoon('Microsoft sign-in')),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _socialButton(
                    'Apple', Icons.apple_rounded, () => _comingSoon('Apple sign-in')),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ",
                        style: TextStyle(color: Colors.white70)),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SaasConnectRegisterPage()),
                        );
                      },
                      child: const Text('Sign Up',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _socialButton(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white54),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
