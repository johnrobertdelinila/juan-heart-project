import 'package:flutter/material.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';

/// Reusable loading indicator for deferred/lazy-loaded screens
/// Shows a centered progress indicator with optional error handling
class DeferredLoadingIndicator extends StatelessWidget {
  final String? message;
  final bool showLogo;

  const DeferredLoadingIndicator({
    super.key,
    this.message,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.whiteBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showLogo) ...[
              Image.asset(
                ImageConstant.imgHealthify,
                height: 60,
                width: 60,
              ),
              const SizedBox(height: 24),
            ],
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ColorConstant.lightBlue,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: JHTextStyles.bodySmall.copyWith(
                  color: ColorConstant.bluedark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error widget for failed deferred loading
class DeferredLoadingError extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;

  const DeferredLoadingError({
    super.key,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.whiteBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: ColorConstant.lightRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to Load Screen',
                style: JHTextStyles.h5.copyWith(
                  color: ColorConstant.bluedark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ?? 'An error occurred while loading this screen.',
                textAlign: TextAlign.center,
                style: JHTextStyles.bodySmall.copyWith(
                  color: ColorConstant.gray,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstant.lightBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: JHTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
