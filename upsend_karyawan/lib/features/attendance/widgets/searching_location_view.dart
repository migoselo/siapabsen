import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

class SearchingLocationGate extends StatefulWidget {
  const SearchingLocationGate({super.key});

  @override
  State<SearchingLocationGate> createState() => _SearchingLocationGateState();
}

class _SearchingLocationGateState extends State<SearchingLocationGate> {
  bool _showLoading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showLoading = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showLoading) {
      return const SizedBox.shrink();
    }
    return const _SearchingLocationView();
  }
}

class _SearchingLocationView extends StatefulWidget {
  const _SearchingLocationView();

  @override
  State<_SearchingLocationView> createState() => _SearchingLocationViewState();
}

class _SearchingLocationViewState extends State<_SearchingLocationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  static const Color strokeColor = Color(0xFF344997);
  static const Color fillColor = Color(0xFF4F8BFF);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DottedBorder(
            options: CircularDottedBorderOptions(
              color: strokeColor,
              strokeWidth: 2,
              dashPattern: const [6, 5],
            ),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fillColor.withOpacity(0.08),
              ),
            ),
          ),
          ScaleTransition(
            scale: _scaleAnimation,
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: fillColor.withOpacity(0.15),
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: strokeColor, width: 2),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: strokeColor,
                      size: 30,
                    ),
                  ),
                  const Positioned(
                    top: 20,
                    left: 25,
                    child: _MiniPinBadge(color: strokeColor),
                  ),
                  const Positioned(
                    top: 30,
                    right: 30,
                    child: _MiniPinBadge(color: fillColor),
                  ),
                  const Positioned(
                    bottom: 35,
                    right: 20,
                    child: _MiniPinBadge(color: Color(0xFF06B6D4)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPinBadge extends StatelessWidget {
  final Color color;
  const _MiniPinBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(Icons.location_on, color: color, size: 16),
    );
  }
}