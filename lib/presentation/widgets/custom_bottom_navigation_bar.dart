import 'package:flutter/material.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/presentation/widgets/cached_image.dart';
import 'package:juan_heart/services/sync_queue_service.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int activeIndex;
  final VoidCallback onPressHome,
      onPressPieChart,
      onPressSOS,
      onPressAppointments,
      onPressProfile;

  const CustomBottomNavigationBar(
      {super.key,
      required this.activeIndex,
      required this.onPressHome,
      required this.onPressPieChart,
      required this.onPressSOS,
      required this.onPressAppointments,
      required this.onPressProfile});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _customButtonIcon(
            onPressHome,
            CachedIconImage(
              assetPath: activeIndex == 0
                  ? ImageConstant.iconHomeDark
                  : ImageConstant.iconHomeLight,
              size: 24,
              fit: BoxFit.contain,
            ),
          ),
          _customButtonIconWithBadge(
            onPressPieChart,
            CachedIconImage(
              assetPath: activeIndex == 1
                  ? ImageConstant.iconPieChartDark
                  : ImageConstant.iconPieChartLight,
              size: 24,
              fit: BoxFit.contain,
            ),
            showBadge: _shouldShowSyncBadge(),
          ),
          GestureDetector(
            onTap: onPressSOS,
            child: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: ColorConstant.lightRed,
                borderRadius: BorderRadius.circular(
                  100,
                ),
              ),
              child: Center(
                child: CachedIconImage(
                  assetPath: ImageConstant.imgHealthify,
                  size: 30,
                ),
              ),
            ),
          ),
          _customButtonIcon(
            onPressAppointments,
            Icon(
              Icons.calendar_today,
              color: activeIndex == 2
                  ? ColorConstant.bluedark
                  : ColorConstant.gentleGray,
              size: 24,
            ),
          ),
          _customButtonIcon(
            onPressProfile,
            CachedIconImage(
              assetPath: activeIndex == 3
                  ? ImageConstant.iconPersonDark
                  : ImageConstant.iconPersonLight,
              size: 24,
              fit: BoxFit.contain,
            ),
          )
        ],
      ),
    );
  }

  Widget _customButtonIcon(VoidCallback onPress, Widget icon) {
    return IconButton(
      onPressed: onPress,
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        height: 24,
        width: 24,
        child: icon,
      ),
    );
  }

  Widget _customButtonIconWithBadge(
    VoidCallback onPress,
    Widget icon, {
    required bool showBadge,
  }) {
    return IconButton(
      onPressed: onPress,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: 24,
            width: 24,
            child: icon,
          ),
          if (showBadge)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: ColorConstant.lightRed,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _shouldShowSyncBadge() {
    final failedCount = SyncQueueService().getFailedCount();
    return failedCount > 0;
  }
}
