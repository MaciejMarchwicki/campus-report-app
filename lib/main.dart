import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'login_screen.dart';

import 'contact_us.dart';
import 'campus_map.dart';
import 'alert_me.dart';
import 'app_language.dart';

// ------------------------------------------------------------
// APP STYLE - same visual style as the admin panel
// ------------------------------------------------------------
const Color appTopBarColor = Color(0xFF8B0002);
const Color appTopBarTextColor = Color(0xFFFFFFFF);

const Color appBackgroundColor = Color(0xFFF4F6FA);
const Color appSidebarColor = Color(0xFFFFFFFF);
const Color appCardColor = Color(0xFFFFFFFF);

const Color appPrimaryColor = Color(0xFF8B0002);
const Color appPrimaryDarkColor = Color(0xFF650001);
const Color appAccentColor = Color(0xFFF4E6E6);

const Color appTextColor = Color(0xFF1F2937);
const Color appMutedTextColor = Color(0xFF667085);
const Color appBorderColor = Color(0xFFD7DCE8);
const Color appImagePlaceholderColor = Color(0xFFEEF2F7);

const Color appDangerColor = Color(0xFFDC2626);
const Color appWarningColor = Color(0xFFF59E0B);
const Color appInfoColor = Color(0xFF2563EB);
const Color appSuccessColor = Color(0xFF16A34A);


// ------------------------------------------------------------
// SUPABASE CONFIG
// ------------------------------------------------------------
const String supabaseUrl = 'https://soktybwssavqcqpqxsar.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNva3R5Yndzc2F2cWNxcHF4c2FyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5MzE4NjMsImV4cCI6MjA5NjUwNzg2M30.4HUKudK2siCTwqJxWGBIW9YvAj-du-kVHg4EFt3kDCI';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const PolitechnikaAlertApp());
}

class PolitechnikaAlertApp extends StatelessWidget {
  const PolitechnikaAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      title: 'CAMPUS REPORT SYSTEM',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: appBackgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: appPrimaryColor,
          primary: appPrimaryColor,
          secondary: appAccentColor,
          surface: appCardColor,
          error: appDangerColor,
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: appTextColor,
              displayColor: appTextColor,
            ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: appPrimaryColor,
            foregroundColor: appTopBarTextColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: appPrimaryColor,
            foregroundColor: appTopBarTextColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: appPrimaryColor,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
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
        cardTheme: CardThemeData(
          color: appCardColor,
          elevation: 2,
          surfaceTintColor: appCardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: appBorderColor),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: appPrimaryDarkColor,
          contentTextStyle: TextStyle(color: appTopBarTextColor),
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: 'auth_token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: appBackgroundColor,
      body: Center(
        child: CircularProgressIndicator(
          color: appPrimaryColor,
        ),
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

// ------------------------------------------------------------
// PUBLIC REPORT MODEL
// This model represents one row from the reports table.
// Comments are not loaded here because comments are admin-only.
// ------------------------------------------------------------
class PublicReport {
  final int id;
  final String description;
  final String locationLabel;
  final String campus;
  final String? status;
  final String? imagePath;
  final DateTime createdAt;

  PublicReport({
    required this.id,
    required this.description,
    required this.locationLabel,
    required this.campus,
    required this.status,
    required this.imagePath,
    required this.createdAt,
  });

  factory PublicReport.fromJson(Map<String, dynamic> json) {
    return PublicReport(
      id: (json['id'] as num).toInt(),
      description: json['description'] as String? ?? '',
      locationLabel: json['location_label'] as String? ?? '',
      campus: json['campus'] as String? ?? '-',
      status: json['status'] as String?,
      imagePath: json['image_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  String get imageUrl {
    if (imagePath == null || imagePath!.isEmpty) return '';

    return supabase.storage
        .from('report_images')
        .getPublicUrl(imagePath!);
  }
}

String statusLabel(AppLanguage lang, String? status) {
  switch (status) {
    case 'to_check':
      return tr(lang, 'To be checked', 'Do sprawdzenia');
    case 'in_progress':
      return tr(lang, 'In progress', 'W trakcie');
    case 'done':
      return tr(lang, 'Resolved', 'Załatwione');
    default:
      return tr(lang, 'No status yet', 'Brak statusu');
  }
}

Color statusColor(String? status) {
  switch (status) {
    case 'to_check':
      return appWarningColor;
    case 'in_progress':
      return appInfoColor;
    case 'done':
      return appSuccessColor;
    default:
      return appMutedTextColor;
  }
}

String formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year} ${two(date.hour)}:${two(date.minute)}';
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isMobileMenuOpen = false;

  AppLanguage _language = AppLanguage.en;

  bool _loadingReports = true;
  String? _loadError;
  List<PublicReport> _reports = [];

  void _changeLanguage(AppLanguage language) {
    setState(() {
      _language = language;
    });
  }

  Future<void> _logout() async {
    await const FlutterSecureStorage().delete(key: 'auth_token');
    await const FlutterSecureStorage().delete(key: 'user_email');
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loadingReports = true;
      _loadError = null;
    });

    try {
      final rows = await supabase
          .from('reports')
          .select()
          .order('created_at', ascending: false);

      final loaded = rows
          .map<PublicReport>((row) => PublicReport.fromJson(row))
          .toList();

      if (!mounted) return;

      setState(() {
        _reports = loaded;
        _loadingReports = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadError =
            '${tr(_language, 'Could not load reports', 'Nie udało się pobrać zgłoszeń')}: $e';
        _loadingReports = false;
      });
    }
  }

  void _openMobileMenu() {
    setState(() {
      _isMobileMenuOpen = true;
    });
  }

  void _closeMobileMenu() {
    if (!_isMobileMenuOpen) return;

    setState(() {
      _isMobileMenuOpen = false;
    });
  }

  void _closeDrawerIfOpen() {
    _closeMobileMenu();
  }

  Future<void> _openAlertPage() async {
    _closeDrawerIfOpen();

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AlertMePage(
          language: _language,
          onLanguageChanged: _changeLanguage,
        ),
      ),
    );

    if (created == true) {
      await _loadReports();
    }
  }

  void _openCampusMapPage() {
    _closeDrawerIfOpen();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CampusMapPage(),
      ),
    );
  }

  void _openContactPage() {
    _closeDrawerIfOpen();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ContactUsPage(),
      ),
    );
  }

  Widget _buildTopBar({
    required bool isNarrow,
  }) {
    final titleWidget = Text(
      'CAMPUS REPORT SYSTEM',
      softWrap: true,
      maxLines: isNarrow ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: appTopBarTextColor,
        fontSize: isNarrow ? 23 : 26,
        fontWeight: FontWeight.bold,
      ),
    );

    final actionsWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LanguageToggle(
          language: _language,
          onChanged: _changeLanguage,
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _logout,
          child: Text(tr(_language, 'Log out', 'Wyloguj')),
        ),
      ],
    );

    if (isNarrow) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
        color: appTopBarColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: tr(_language, 'Open menu', 'Otwórz menu'),
                  onPressed: _openMobileMenu,
                  icon: const Icon(
                    Icons.menu,
                    color: appTopBarTextColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: titleWidget,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: actionsWidget,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      color: appTopBarColor,
      child: Row(
        children: [
          Expanded(
            child: titleWidget,
          ),
          const SizedBox(width: 16),
          actionsWidget,
        ],
      ),
    );
  }

  Widget _buildNavigationMenu({
    required bool inDrawer,
  }) {
    return Container(
      color: appSidebarColor,
      child: SafeArea(
        top: inDrawer,
        bottom: inDrawer,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (inDrawer) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 10, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr(_language, 'Menu', 'Menu'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: appTextColor,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: tr(_language, 'Close', 'Zamknij'),
                        onPressed: _closeMobileMenu,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
              _NavigationButton(
                icon: Icons.add_alert_outlined,
                label: tr(_language, 'Create report', 'Utwórz zgłoszenie'),
                onPressed: _openAlertPage,
              ),
              _NavigationButton(
                icon: Icons.map_outlined,
                label: tr(_language, 'Campus Map', 'Mapa kampusu'),
                onPressed: _openCampusMapPage,
              ),
              _NavigationButton(
                icon: Icons.admin_panel_settings_outlined,
                label: tr(_language, 'Administrators', 'Administratorzy'),
                onPressed: _openAlertPage, // do zmiany później
              ),
              const Spacer(),
              _NavigationButton(
                icon: Icons.contact_support_outlined,
                label: tr(_language, 'Contact Us!', 'Kontakt'),
                onPressed: _openContactPage,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: _loadReports,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clickable report card in the middle of the home page.
              InkWell(
                onTap: _openAlertPage,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 230,
                  ),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 10,
                        color: Colors.black12,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.report_problem_outlined,
                        size: 60,
                        color: appPrimaryColor,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        tr(_language, 'Report an Issue', 'Zgłoś problem'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        tr(
                          _language,
                          'Tell us what happened and where.',
                          'Powiedz nam, co się stało i gdzie.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.circle,
                    size: 14,
                    color: appPrimaryColor,
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.circle_outlined, size: 14),
                  SizedBox(width: 8),
                  Icon(Icons.circle_outlined, size: 14),
                ],
              ),

              const SizedBox(height: 40),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      tr(_language, 'Latest Reports', 'Ostatnie zgłoszenia'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: tr(_language, 'Refresh', 'Odśwież'),
                    onPressed: _loadReports,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _ReportsHorizontalList(
                language: _language,
                loading: _loadingReports,
                error: _loadError,
                reports: _reports,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 760;

        return Scaffold(
          body: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(isNarrow: isNarrow),
                  Expanded(
                    child: isNarrow
                        ? _buildMainContent()
                        : Row(
                            children: [
                              SizedBox(
                                width: 220,
                                child: _buildNavigationMenu(inDrawer: false),
                              ),
                              Expanded(
                                child: _buildMainContent(),
                              ),
                            ],
                          ),
                  ),
                ],
              ),

              // Custom mobile drawer. It slides from the left side on narrow screens.
              if (isNarrow) ...[
                IgnorePointer(
                  ignoring: !_isMobileMenuOpen,
                  child: AnimatedOpacity(
                    opacity: _isMobileMenuOpen ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: GestureDetector(
                      onTap: _closeMobileMenu,
                      child: Container(
                        color: Colors.black.withOpacity(0.35),
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  top: 0,
                  bottom: 0,
                  left: _isMobileMenuOpen ? 0 : -290,
                  width: 280,
                  child: Material(
                    color: appSidebarColor,
                    elevation: 12,
                    child: _buildNavigationMenu(inDrawer: true),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
      ),
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        foregroundColor: appPrimaryColor,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}

class _ReportsHorizontalList extends StatefulWidget {
  const _ReportsHorizontalList({
    required this.language,
    required this.loading,
    required this.error,
    required this.reports,
  });

  final AppLanguage language;
  final bool loading;
  final String? error;
  final List<PublicReport> reports;

  @override
  State<_ReportsHorizontalList> createState() => _ReportsHorizontalListState();
}

class _ReportsHorizontalListState extends State<_ReportsHorizontalList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: CircularProgressIndicator(
            color: appPrimaryColor,
          ),
        ),
      );
    }

    if (widget.error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          widget.error!,
          style: const TextStyle(color: appDangerColor),
        ),
      );
    }

    if (widget.reports.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          tr(widget.language, 'No reports yet.', 'Brak zgłoszeń.'),
        ),
      );
    }

    return SizedBox(
      height: 360,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        notificationPredicate: (notification) {
          return notification.metrics.axis == Axis.horizontal;
        },
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.only(
            right: 16,
            bottom: 18,
          ),
          itemCount: widget.reports.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            return _ReportPreviewCard(
              report: widget.reports[index],
              language: widget.language,
            );
          },
        ),
      ),
    );
  }
}

class _ReportPreviewCard extends StatelessWidget {
  const _ReportPreviewCard({
    required this.report,
    required this.language,
  });

  final PublicReport report;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 135,
              width: double.infinity,
              child: report.imageUrl.isEmpty
                  ? Container(
                      color: appImagePlaceholderColor,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: appPrimaryColor,
                        size: 42,
                      ),
                    )
                  : Image.network(
                      report.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: appImagePlaceholderColor,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: appPrimaryColor,
                            size: 42,
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            report.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${tr(language, 'Campus', 'Kampus')} ${report.campus} • ${report.locationLabel}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatDate(report.createdAt),
                  style: TextStyle(
                    color: appMutedTextColor,
                    fontSize: 12,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  statusLabel(language, report.status),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor(report.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
