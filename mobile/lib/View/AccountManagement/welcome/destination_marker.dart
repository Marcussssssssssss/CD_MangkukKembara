import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DestinationMarker extends StatelessWidget {
  const DestinationMarker({
    super.key,
    required this.label,
    required this.imageAsset,
    required this.center,
    required this.arrival,
  });

  final String label;
  final String imageAsset;
  final Offset center;
  final Animation<double> arrival;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - 50,
      // The supplied route anchors represent the map-pin tip, not the photo
      // centre. Keeping this offset in the design coordinate space makes the
      // route land on each pin on every screen size.
      top: center.dy - 110,
      width: 100,
      height: 148,
      child: AnimatedBuilder(
        animation: arrival,
        builder: (context, child) {
          // easeOutBack may overshoot. It is used only for marker scale; every
          // value passed into a curve or opacity is clamped first.
          final scaleValue = arrival.value;
          final value = scaleValue.clamp(0.0, 1.0).toDouble();
          final scale = .72 + scaleValue * .28;
          final pinOffset = 8 * (1 - Curves.easeOutCubic.transform(value));
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  if (value < .72)
                    Positioned(
                      top: 6,
                      child: Container(
                        width: 82 + 46 * value,
                        height: 82 + 46 * value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0x99FFF8EC).withOpacity(1 - value),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66012F32),
                              blurRadius: 9,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFFFF8EC),
                            width: 4,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            imageAsset,
                            width: 82,
                            height: 82,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, pinOffset - 5),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFFE6604B),
                          size: 36,
                          shadows: [
                            Shadow(
                              color: Color(0x66012F32),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, 5 * (1 - value)),
                        child: Text(
                          label,
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFFFFF8EC),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            shadows: const [
                              Shadow(color: Color(0x99012F32), blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
