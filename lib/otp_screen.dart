import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../app_language.dart';
import 'login_screen.dart' show kBackendUrl;

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.email,
    required this.language,
  });

  final String email;
  final AppLanguage language;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final _storage = const FlutterSecureStorage();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  int _resendSeconds = 60;
  Timer? _timer;

  AppLanguage get _language => widget.language;

  @override
  void initState() {
    super.initState();
    _startResendTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startResendTimer() {
    setState(() => _resendSeconds = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  String get _otpCode => _controllers.map((controller) => controller.text).join();

  void _onDigitChanged(int index, String value) {
    setState(() => _hasError = false);

    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_otpCode.length == 6) {
      _verifyOtp();
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) {
      setState(() {
        _hasError = true;
        _errorMessage = tr(
          _language,
          'Please enter all 6 digits.',
          'Wpisz wszystkie 6 cyfr.',
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.post(
        Uri.parse('$kBackendUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'otp': _otpCode,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final customToken = data['token'] as String;
        final userCredential = await _auth.signInWithCustomToken(customToken);

        final idToken = await userCredential.user?.getIdToken();

        await _storage.write(key: 'auth_token', value: idToken);
        await _storage.write(key: 'user_email', value: widget.email);

        if (!mounted) return;

        setState(() => _isLoading = false);

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = data['error'] ??
              tr(
                _language,
                'Incorrect code. Please try again.',
                'Nieprawidłowy kod. Spróbuj ponownie.',
              );
        });

        for (final controller in _controllers) {
          controller.clear();
        }

        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = tr(
          _language,
          'Cannot reach server. Please try again.',
          'Nie można połączyć się z serwerem. Spróbuj ponownie.',
        );
      });
    }
  }

  Future<void> _resendCode() async {
    if (_resendSeconds > 0) return;

    try {
      final response = await http.post(
        Uri.parse('$kBackendUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                _language,
                'Code resent to ${widget.email}.',
                'Kod został ponownie wysłany na ${widget.email}.',
              ),
            ),
            backgroundColor: const Color(0xFF8B0002),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              _language,
              'Could not resend. Please try again.',
              'Nie udało się wysłać ponownie. Spróbuj jeszcze raz.',
            ),
          ),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();

    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CAMPUS REPORT SYSTEM',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4E6E6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: Color(0xFF8B0002),
                  size: 34,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                tr(_language, 'Check your email', 'Sprawdź swój e-mail'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: tr(
                        _language,
                        'We sent a 6-digit code to\n',
                        'Wysłaliśmy 6-cyfrowy kod na\n',
                      ),
                    ),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B0002),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) => _onKeyEvent(index, event),
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onDigitChanged(index, value),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: _hasError
                              ? const Color(0xFFFFF5F5)
                              : const Color(0xFFF5F7FA),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _hasError
                                  ? const Color(0xFFE53E3E)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _hasError
                                  ? const Color(0xFFE53E3E)
                                  : const Color(0xFF8B0002),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              if (_hasError) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 15,
                      color: Color(0xFFE53E3E),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFE53E3E),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B0002),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF8B0002).withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          tr(_language, 'Verify email', 'Zweryfikuj e-mail'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: _resendSeconds > 0
                    ? Text(
                        tr(
                          _language,
                          'Resend code in ${_resendSeconds}s',
                          'Wyślij ponownie za ${_resendSeconds}s',
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      )
                    : TextButton(
                        onPressed: _resendCode,
                        child: Text(
                          tr(_language, 'Resend code', 'Wyślij kod ponownie'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8B0002),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  tr(
                    _language,
                    'Check your spam folder if you do not see it.',
                    'Sprawdź folder spam, jeśli nie widzisz wiadomości.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
