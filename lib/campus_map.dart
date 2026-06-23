import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_language.dart';

class CampusMapPage extends StatelessWidget {
  const CampusMapPage({
    super.key,
    required this.language,
  });

  final AppLanguage language;

  Future<void> _openCampusMap(BuildContext context) async {
    final uri = Uri.parse('https://nav.p.lodz.pl/');

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              language,
              'Could not open map.',
              'Nie udało się otworzyć mapy.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0002),
        foregroundColor: Colors.white,
        title: Text(
          tr(
            language,
            'Campus Map',
            'Mapa kampusu',
          ),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: 280,
          height: 80,
          child: FilledButton.icon(
            onPressed: () => _openCampusMap(context),
            icon: const Icon(
              Icons.open_in_new_rounded,
              size: 30,
            ),
            label: Text(
              tr(
                language,
                'Open map',
                'Otwórz mapę',
              ),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}