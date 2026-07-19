import 'package:flutter/material.dart';
import 'step_progress_bar.dart';

class AttendanceStepper extends StatelessWidget {
  final int currentStep;
  final Widget child;

  const AttendanceStepper({
    super.key,
    required this.currentStep,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StepProgressBar(currentStep: currentStep),
        Expanded(child: child),
      ],
    );
  }
}
