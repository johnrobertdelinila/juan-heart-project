import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';

/// iOS-style "Slide to Unlock" button for confirming critical actions
///
/// Features:
/// - Smooth drag interaction from left to right
/// - Animated chevrons that move with the thumb
/// - Text fades as user slides
/// - Haptic feedback at completion threshold
/// - Auto-complete animation when threshold reached
/// - Spring-back animation if released early
/// - Accessibility: tap anywhere to complete
class SlideToConfirmButton extends StatefulWidget {
  final VoidCallback onConfirm;
  final String text;
  final Color backgroundColor;
  final Color thumbColor;
  final Color textColor;
  final IconData icon;
  final double height;
  final double completionThreshold;

  const SlideToConfirmButton({
    Key? key,
    required this.onConfirm,
    this.text = 'Slide to Continue',
    this.backgroundColor = Colors.blue,
    this.thumbColor = Colors.white,
    this.textColor = Colors.white,
    this.icon = Icons.arrow_forward,
    this.height = 56.0,
    this.completionThreshold = 0.8,
  }) : super(key: key);

  @override
  State<SlideToConfirmButton> createState() => _SlideToConfirmButtonState();
}

class _SlideToConfirmButtonState extends State<SlideToConfirmButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  bool _hasTriggeredHaptic = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    )..addListener(() {
        setState(() {
          _dragPosition = _slideAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxWidth) {
    if (_isCompleted) return;

    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxWidth);

      // Trigger haptic feedback when reaching completion threshold
      final progress = _dragPosition / maxWidth;
      if (progress >= widget.completionThreshold && !_hasTriggeredHaptic) {
        HapticFeedback.mediumImpact();
        _hasTriggeredHaptic = true;
      } else if (progress < widget.completionThreshold && _hasTriggeredHaptic) {
        _hasTriggeredHaptic = false;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double maxWidth) {
    if (_isCompleted) return;

    final progress = _dragPosition / maxWidth;

    if (progress >= widget.completionThreshold) {
      // Complete the action
      _completeSlide(maxWidth);
    } else {
      // Reset to start
      _slideAnimation = Tween<double>(
        begin: _dragPosition,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutBack,
        ),
      );
      _animationController.forward(from: 0.0);
      _hasTriggeredHaptic = false;
    }
  }

  void _completeSlide(double maxWidth) {
    setState(() {
      _isCompleted = true;
    });

    // Animate to end
    _slideAnimation = Tween<double>(
      begin: _dragPosition,
      end: maxWidth,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward(from: 0.0).then((_) {
      // Trigger haptic feedback on completion
      HapticFeedback.heavyImpact();

      // Call the callback after a brief delay for visual feedback
      Future.delayed(const Duration(milliseconds: 200), () {
        widget.onConfirm();
      });
    });
  }

  void _onTap(double maxWidth) {
    // Accessibility: tap to complete
    if (!_isCompleted) {
      _completeSlide(maxWidth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final thumbWidth = widget.height - 8;
        final maxDragDistance = maxWidth - thumbWidth - 8;
        final progress = _dragPosition / maxDragDistance;

        return GestureDetector(
          onTap: () => _onTap(maxDragDistance),
          onHorizontalDragUpdate: (details) =>
              _onHorizontalDragUpdate(details, maxDragDistance),
          onHorizontalDragEnd: (details) =>
              _onHorizontalDragEnd(details, maxDragDistance),
          child: Container(
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.backgroundColor
                      .withAlpha(128), // 0.5 opacity = 128 alpha
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background text (fades as slider moves)
                Center(
                  child: Opacity(
                    opacity: (1.0 - progress).clamp(0.0, 1.0),
                    child: Text(
                      widget.text,
                      style: JHTextStyles.h5.copyWith(
                        color: widget.textColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Animated chevrons that follow the thumb
                Positioned.fill(
                  child: Opacity(
                    opacity: (1.0 - progress).clamp(0.0, 1.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (int i = 0; i < 3; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              right: 12.0 + (i * 8),
                              left: i == 0 ? 0 : 0,
                            ),
                            child: Transform.translate(
                              offset: Offset(progress * 20, 0),
                              child: Icon(
                                Icons.chevron_right,
                                color: widget.textColor.withAlpha(
                                  ((0.3 + (i * 0.2)) * 255)
                                      .round(), // Convert opacity to alpha
                                ),
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Draggable thumb
                Positioned(
                  left: 4 + _dragPosition,
                  top: 4,
                  child: Container(
                    width: thumbWidth,
                    height: thumbWidth,
                    decoration: BoxDecoration(
                      color: widget.thumbColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withAlpha(51), // 0.2 opacity = 51 alpha
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.backgroundColor,
                      size: 28,
                    ),
                  ),
                ),

                // Success checkmark overlay (shows after completion)
                if (_isCompleted)
                  Center(
                    child: Icon(
                      Icons.check_circle,
                      color: widget.textColor,
                      size: 36,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
