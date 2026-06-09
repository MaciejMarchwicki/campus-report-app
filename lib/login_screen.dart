import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../app_language.dart';
import 'otp_screen.dart';

// Allowed university email domain.
const String kUniversityDomain = 'edu.p.lodz.pl';

// Your existing backend that sends and verifies OTP codes.
const String kBackendUrl = 'https://campus-backend-jfkb.onrender.com';

const Color appTopBarColor = Color(0xFF8B0002);
const Color appBackgroundColor = Color(0xFFF4F6FA);
const Color appCardColor = Colors.white;
const Color appPrimaryColor = Color(0xFF8B0002);
const Color appPrimaryDarkColor = Color(0xFF650001);
const Color appAccentColor = Color(0xFFF4E6E6);
const Color appTextColor = Color(0xFF1F2937);
const Color appMutedTextColor = Color(0xFF667085);
const Color appBorderColor = Color(0xFFD7DCE8);
const Color appDangerColor = Color(0xFFDC2626);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  AppLanguage _language = AppLanguage.en;
  bool _isLoading = false;

  void _changeLanguage(AppLanguage language) {
    setState(() {
      _language = language;
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return tr(
        _language,
        'Please enter your university email.',
        'Wpisz swój adres e-mail uczelni.',
      );
    }

    final trimmed = value.trim().toLowerCase();

    if (!trimmed.endsWith('@$kUniversityDomain')) {
      return tr(
        _language,
        'Email must end with @$kUniversityDomain.',
        'Adres e-mail musi kończyć się na @$kUniversityDomain.',
      );
    }

    final localPart = trimmed.split('@').first;
    final localPartRegex = RegExp(r'^[\w.+\-]+$');

    if (localPart.isEmpty || !localPartRegex.hasMatch(localPart)) {
      return tr(
        _language,
        'Please enter a valid email address.',
        'Wpisz poprawny adres e-mail.',
      );
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim().toLowerCase();

    try {
      final response = await http.post(
        Uri.parse('$kBackendUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              email: email,
              language: _language,
            ),
          ),
        );
      } else {
        _showError(
          data['error'] ??
              tr(
                _language,
                'Could not send code. Please try again.',
                'Nie udało się wysłać kodu. Spróbuj ponownie.',
              ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showError(
        tr(
          _language,
          'Cannot reach server. Please try again.',
          'Nie można połączyć się z serwerem. Spróbuj ponownie.',
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: appDangerColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: Column(
        children: [
          _LoginTopBar(
            language: _language,
            onLanguageChanged: _changeLanguage,
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Card(
                    color: appCardColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: appBorderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: appAccentColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.location_city_rounded,
                                color: appPrimaryColor,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              tr(
                                _language,
                                'Report issues on the campus',
                                'Zgłoś problem lub usterkę na kampusie',
                              ),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: appTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tr(
                                _language,
                                'Sign in with your university email to report campus issues.',
                                'Zaloguj się mailem uczelnianym, aby utworzyć zgłoszenie.',
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                color: appMutedTextColor,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              tr(_language, 'University email', 'E-mail'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: appTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                hintText: 'you@$kUniversityDomain',
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                  color: appPrimaryColor,
                                ),
                                filled: true,
                                fillColor: appCardColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: appBorderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: appBorderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: appPrimaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 14,
                                  color: appMutedTextColor,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    tr(
                                      _language,
                                      'Only @$kUniversityDomain addresses accepted',
                                      'Akceptowane są tylko adresy @$kUniversityDomain',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: appMutedTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appPrimaryColor,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      appPrimaryColor.withOpacity(0.6),
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
                                        tr(
                                          _language,
                                          'Send verification code',
                                          'Wyślij kod weryfikacyjny',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Text(
                                tr(
                                  _language,
                                  'A 6-digit code will be sent to your email.',
                                  '6-cyfrowy kod zostanie wysłany na Twój e-mail.',
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: appMutedTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginTopBar extends StatelessWidget {
  const _LoginTopBar({
    required this.language,
    required this.onLanguageChanged,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 22,
      ),
      color: appTopBarColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;

          final title = const Text(
            'CAMPUS REPORT SYSTEM',
            softWrap: true,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          );

          final languageToggle = _LanguageToggle(
            language: language,
            onChanged: onLanguageChanged,
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: languageToggle,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              languageToggle,
            ],
          );
        },
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({
    required this.language,
    required this.onChanged,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChoiceChip(
          label: const Text('EN'),
          selected: language == AppLanguage.en,
          showCheckmark: false,
          selectedColor: appAccentColor,
          backgroundColor: appCardColor,
          side: const BorderSide(color: appAccentColor),
          labelStyle: TextStyle(
            color: language == AppLanguage.en
                ? appPrimaryDarkColor
                : appTopBarColor,
            fontWeight: FontWeight.w700,
          ),
          onSelected: (_) => onChanged(AppLanguage.en),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('POL'),
          selected: language == AppLanguage.pl,
          showCheckmark: false,
          selectedColor: appAccentColor,
          backgroundColor: appCardColor,
          side: const BorderSide(color: appAccentColor),
          labelStyle: TextStyle(
            color: language == AppLanguage.pl
                ? appPrimaryDarkColor
                : appTopBarColor,
            fontWeight: FontWeight.w700,
          ),
          onSelected: (_) => onChanged(AppLanguage.pl),
        ),
      ],
    );
  }
}
