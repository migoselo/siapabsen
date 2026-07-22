import 'package:flutter/material.dart';
import '../models/location_model.dart';

class LocationCard extends StatelessWidget {
  final LocationModel location;

  const LocationCard({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    final bool inRange = location.withinRadius;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: inRange ? const Color(0xFFE2E8F0) : const Color(0xFFFECACA),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: inRange
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.map_outlined,
              color: inRange
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFDC2626),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.track_changes,
                      size: 14,
                      color: inRange
                          ? Colors.grey.shade500
                          : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      inRange
                          ? "Di dalam radius ${location.distance.toStringAsFixed(0)}m"
                          : "Di luar radius ${location.distance.toStringAsFixed(0)}m dari ${location.radiusMeter}m ",
                      style: TextStyle(
                        fontSize: 12,
                        color: inRange
                            ? Colors.grey.shade600
                            : const Color(0xFFDC2626),
                        fontWeight: inRange
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
