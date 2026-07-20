import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'minidenticon_generator.dart';

class IdenticonAvatar extends StatelessWidget {
  final String username;
  final double size;

  const IdenticonAvatar({super.key, required this.username, this.size = 120.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.black12,
        shape: BoxShape.circle,
      ),
      padding: EdgeInsets.all(
        size * 0.1,
      ), // Memberikan jarak agar SVG presisi di dalam lingkaran
      child: SvgPicture.string(minidenticon(username), fit: BoxFit.contain),
    );
  }
}
