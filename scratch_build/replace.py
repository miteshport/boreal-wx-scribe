import re

with open('../lib/presentation/pages/redesign/today_tab_view.dart', 'r', encoding='utf-8') as f:
    content = f.read()

replacement = '''class _EnvironmentalDeck extends StatefulWidget {
  final CanadianIntelPayload? intel;
  final bool isLoading;

  const _EnvironmentalDeck({this.intel, this.isLoading = false});

  @override
  State<_EnvironmentalDeck> createState() => _EnvironmentalDeckState();
}

class _EnvironmentalDeckState extends State<_EnvironmentalDeck> with SingleTickerProviderStateMixin {
  late AnimationController _borderController;
  late Animation<double> _borderOpacity;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _borderOpacity = Tween<double>(begin: 0.3, end: 1.0).animate(_borderController);
    
    if (!widget.isLoading && widget.intel != null) {
      _borderController.forward();
    }
  }

  @override
  void didUpdateWidget(_EnvironmentalDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading && widget.intel != null) {
      _borderController.forward(from: 0.0);
    } else if (!oldWidget.isLoading && widget.isLoading) {
      _borderController.reset();
    } else if (!widget.isLoading && oldWidget.intel != widget.intel) {
      _borderController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _borderController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            border: Border.all(
              color: const Color(0xFFFF9900).withValues(alpha: _borderOpacity.value), 
              width: 1
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: child,
        );
      },
      child: widget.isLoading
          ? const Center(
              child: Text(
                '[ INGESTING SATELLITE TELEMETRY... ]',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  color: Color(0xFF00F0FF),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENVIRONMENTAL DECK // SLANG HUD',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    color: const Color(0xFFFF9900).withValues(alpha: 0.8),
                    letterSpacing: 2,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TeletypeText(
                  widget.intel?.slangHeadline ?? '',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF9900),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                    height: 1,
                    color: const Color(0xFFFF9900).withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  'NEWCOMER TIPS',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    color: const Color(0xFFFF9900).withValues(alpha: 0.8),
                    letterSpacing: 2,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TeletypeText(
                  widget.intel?.lifestyleActivity ?? '',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
    );
  }
}

class _DockedCard extends StatefulWidget {
  final CanadianIntelPayload? intel;
  final bool isLoading;

  const _DockedCard({this.intel, this.isLoading = false});

  @override
  State<_DockedCard> createState() => _DockedCardState();
}

class _DockedCardState extends State<_DockedCard> with SingleTickerProviderStateMixin {
  late AnimationController _borderController;
  late Animation<double> _borderOpacity;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _borderOpacity = Tween<double>(begin: 0.3, end: 1.0).animate(_borderController);
    
    if (!widget.isLoading && widget.intel != null) {
      _borderController.forward();
    }
  }

  @override
  void didUpdateWidget(_DockedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading && widget.intel != null) {
      _borderController.forward(from: 0.0);
    } else if (!oldWidget.isLoading && widget.isLoading) {
      _borderController.reset();
    } else if (!widget.isLoading && oldWidget.intel != widget.intel) {
      _borderController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _borderController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            border: Border.all(
              color: const Color(0xFF00F0FF).withValues(alpha: _borderOpacity.value), 
              width: 1
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: child,
        );
      },
      child: widget.isLoading
          ? const Center(
              child: Text(
                '[ DECRYPTING CANADIAN PULSE... ]',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  color: Color(0xFF00F0FF),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CANADIAN PRIDE PULSE // WISDOM',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.8),
                    letterSpacing: 2,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TeletypeText(
                  widget.intel?.newcomerWisdom ?? '',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
    );
  }
}
'''

start_marker = "class _EnvironmentalDeck extends StatelessWidget {"
end_marker = "class _EnvironmentCanadaButton extends StatelessWidget {"

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)

if start_idx != -1 and end_idx != -1:
    new_content = content[:start_idx] + replacement + content[end_idx:]
    with open('../lib/presentation/pages/redesign/today_tab_view.dart', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Replaced successfully")
else:
    print("Could not find markers")
