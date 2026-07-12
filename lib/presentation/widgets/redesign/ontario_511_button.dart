import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';

class Ontario511Button extends StatelessWidget {
  const Ontario511Button({super.key});

  Future<void> _launch511() async {
    final Uri url = Uri.parse('https://511on.ca/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launch511,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: const Color(0xFFD4FF00), // Solar-Yellow
          border: Border.all(color: const Color(0xFF0A0A0A), width: 2), // 2px solid black border
          borderRadius: BorderRadius.zero, // Sharp 90° corners
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF0A0A0A),
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.traffic_outlined, color: Color(0xFF0A0A0A), size: 18),
            const SizedBox(width: 10),
            Text(
              'OPEN LIVE ONTARIO 511',
              style: AppTypography.monoCaption.copyWith(
                color: const Color(0xFF0A0A0A),
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.open_in_new, color: Color(0xFF0A0A0A), size: 16),
          ],
        ),
      ),
    );
  }
}
