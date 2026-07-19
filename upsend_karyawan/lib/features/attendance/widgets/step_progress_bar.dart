import 'package:flutter/material.dart';

class StepProgressBar extends StatelessWidget {
  final int currentStep;

  const StepProgressBar({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFF006D4C);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 36.0),
      child: Row(
        children: [
          _buildStepCircle(
            1,
            "Lokasi",
            currentStep >= 1,
            currentStep > 1,
            primaryColor,
          ),
          _buildDividerLine(currentStep > 1, primaryColor),
          _buildStepCircle(
            2,
            "Kamera",
            currentStep >= 2,
            currentStep > 2,
            primaryColor,
          ),
          _buildDividerLine(currentStep > 2, primaryColor),
          _buildStepCircle(3, "Selesai", currentStep == 3, false, primaryColor),
        ],
      ),
    );
  }

  Widget _buildStepCircle(
    int stepNum,
    String title,
    bool isActive,
    bool isDone,
    Color activeColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone || isActive ? activeColor : Colors.white,
            border: Border.all(
              color: isDone || isActive ? activeColor : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              "$stepNum",
              style: TextStyle(
                color: isDone || isActive ? Colors.white : Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            color: isActive || isDone ? activeColor : Colors.grey.shade500,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildDividerLine(bool isDone, Color activeColor) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Divider(
          color: isDone ? activeColor : Colors.grey.shade300,
          thickness: 1.5,
        ),
      ),
    );
  }
}
