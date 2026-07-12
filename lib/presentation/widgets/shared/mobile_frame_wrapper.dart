/// mobile_frame_wrapper.dart
///
/// Desktop Web Mobile Preview Frame
/// ─────────────────────────────────────────────────────────────────────────
/// When running on desktop browser (screen width > 600px), this wrapper
/// constrains the entire UI to a centered 430×932 phone frame.
/// On real mobile, it is completely transparent — renders children as-is.
library mobile_frame_wrapper;

import 'package:flutter/material.dart';

class MobileFrameWrapper extends StatelessWidget {
  final Widget child;

  const MobileFrameWrapper({super.key, required this.child});

  // Desktop breakpoint (pixels)
  static const double _breakpoint = 600;
  // iPhone 16 Pro max-width
  static const double _frameWidth = 430;
  // iPhone 16 Pro max-height
  static const double _frameHeight = 932;
  // Corner radius of the phone frame
  static const double _frameRadius = 44;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= _breakpoint) {
          // On real mobile — no wrapper, full native render
          return child;
        }

        // On desktop web — render centered phone frame
        return Container(
          color: const Color(0xFF111111), // Deep grey desktop background
          child: Center(
            child: Container(
              width: _frameWidth,
              height: _frameHeight,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(_frameRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.06),
                    blurRadius: 60,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.9),
                    blurRadius: 120,
                    spreadRadius: 20,
                    offset: const Offset(0, 40),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.10),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_frameRadius - 1),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
