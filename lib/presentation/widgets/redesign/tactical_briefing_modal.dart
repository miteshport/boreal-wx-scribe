import 'package:flutter/material.dart';
import 'package:weather_sync_ca/services/boreal_content_engine.dart';
import 'package:weather_sync_ca/presentation/widgets/redesign/bento_animations.dart';

class TacticalBriefingModal extends StatelessWidget {
  final CanadianIntelPayload? vaultData;

  const TacticalBriefingModal({super.key, required this.vaultData});

  static void show(BuildContext context, CanadianIntelPayload? intel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF00F0FF), // Cyber-Cyan
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (ctx) => TacticalBriefingModal(vaultData: intel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roadTripInfo = vaultData?.roadTripSlang ?? 'Awaiting AI uplink...';
    final cargoManifest = vaultData?.escapeManifest ?? 'Awaiting AI uplink...';
    final newcomerWisdom = vaultData?.newcomerWisdom ?? 'Awaiting AI uplink...';
    final newcomerTips = vaultData?.lifestyleActivity ?? 'Awaiting AI uplink...';

    const Color sheetBg = Color(0xFF00F0FF); // Cyber-Cyan
    const Color textBlack = Color(0xFF0A0A0A);
    const Color dividerClr = Color(0xFF003333);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Pull tab ──────────────────────────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 28),
                    decoration: BoxDecoration(
                      color: textBlack.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Header ─────────────────────────────────────────
                const Text(
                  'CANADIAN SURVIVAL GUIDE',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    color: textBlack,
                    letterSpacing: 3,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // ── Headline ──────────────────────────────────────────
                const Text(
                  'TACTICAL BRIEFING',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: textBlack,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 24),
                Container(height: 1, color: dividerClr),
                const SizedBox(height: 24),

                // ── Content Sections ──────────────────────────────────
                _buildSection(
                  delay: 100,
                  number: '01',
                  title: 'CARGO MANIFEST',
                  body: cargoManifest,
                  textBlack: textBlack,
                  dividerClr: dividerClr,
                ),
                _buildSection(
                  delay: 200,
                  number: '02',
                  title: 'ROAD-TRIP TRANSLATOR & SLANG HUD',
                  body: roadTripInfo,
                  textBlack: textBlack,
                  dividerClr: dividerClr,
                ),
                _buildSection(
                  delay: 300,
                  number: '03',
                  title: 'NEWCOMER TIPS',
                  body: newcomerTips,
                  textBlack: textBlack,
                  dividerClr: dividerClr,
                ),
                _buildSection(
                  delay: 400,
                  number: '04',
                  title: 'CANADIAN PRIDE PULSE',
                  body: newcomerWisdom,
                  textBlack: textBlack,
                  dividerClr: dividerClr,
                  isLast: true,
                ),
                
                const SizedBox(height: 32),
                
                // ── Footer ──────────────────────────────────────────
                Center(
                  child: Text(
                    'UPLINK TERMINATED',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      color: textBlack.withValues(alpha: 0.3),
                      letterSpacing: 2,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required int delay,
    required String number,
    required String title,
    required String body,
    required Color textBlack,
    required Color dividerClr,
    bool isLast = false,
  }) {
    return BentoEntrance(
      delay: Duration(milliseconds: delay),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                number,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  color: textBlack.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '—',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  color: textBlack.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    color: textBlack.withValues(alpha: 0.5),
                    letterSpacing: 2,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TeletypeText(
            body,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: textBlack,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!isLast) ...[
            const SizedBox(height: 24),
            Container(height: 1, color: dividerClr),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
