/// Reusable UI Components for Referral & Care Navigation System
/// 
/// Contains enhanced widgets with emotional design, accessibility,
/// and Filipino cultural elements
///
/// Design Philosophy:
/// - Reassuring and human-centered
/// - Trust-building through visual cues
/// - Bilingual support (English/Tagalog)
/// - Accessible for all ages and literacy levels

import 'package:flutter/material.dart';
import 'package:juan_heart/core/utils/color_constants.dart';
import 'package:juan_heart/models/referral_data.dart';

/// PHC Trust Badge - Displays Philippine Heart Center verification
class PHCTrustBadge extends StatelessWidget {
  final String language;
  
  const PHCTrustBadge({Key? key, required this.language}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ColorConstant.verifiedBadge.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ColorConstant.verifiedBadge.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user,
            size: 16,
            color: ColorConstant.verifiedBadge,
          ),
          const SizedBox(width: 6),
          Text(
            language == 'fil' 
                ? 'Partner ng PHC'
                : 'PHC Verified Partner',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ColorConstant.verifiedBadge,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated Heart Pulse - Indicates system is actively working
class AnimatedHeartPulse extends StatefulWidget {
  final Color color;
  final double size;
  
  const AnimatedHeartPulse({
    Key? key, 
    required this.color,
    this.size = 24,
  }) : super(key: key);
  
  @override
  State<AnimatedHeartPulse> createState() => _AnimatedHeartPulseState();
}

class _AnimatedHeartPulseState extends State<AnimatedHeartPulse> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        Icons.favorite,
        color: widget.color,
        size: widget.size,
      ),
    );
  }
}

/// Reassurance Message - Warm, empathetic guidance text
class ReassuranceMessage extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? backgroundColor;
  
  const ReassuranceMessage({
    Key? key,
    required this.message,
    this.icon = Icons.support_agent,
    this.backgroundColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor ?? ColorConstant.gradientBlueStart,
            backgroundColor?.withOpacity(0.5) ?? ColorConstant.gradientBlueEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstant.calmingBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ColorConstant.calmingBlue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: ColorConstant.calmingBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: ColorConstant.bluedark,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Enhanced Facility Card with contextual badges
class EnhancedFacilityCard extends StatelessWidget {
  final HealthcareFacility facility;
  final String language;
  final bool isSelected;
  final bool showRecommendedBadge;
  final String? recommendationText;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final VoidCallback? onNavigate;
  
  const EnhancedFacilityCard({
    Key? key,
    required this.facility,
    required this.language,
    required this.isSelected,
    this.showRecommendedBadge = false,
    this.recommendationText,
    required this.onTap,
    this.onCall,
    this.onNavigate,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected
            ? ColorConstant.calmingBlue.withOpacity(0.08)
            : ColorConstant.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? ColorConstant.calmingBlue
              : ColorConstant.cardBorder,
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? ColorConstant.calmingBlue.withOpacity(0.15)
                : ColorConstant.cardShadowMedium,
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommended badge (if applicable)
          if (showRecommendedBadge)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorConstant.verifiedBadge.withOpacity(0.15),
                    ColorConstant.verifiedBadge.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.recommend,
                    size: 16,
                    color: ColorConstant.verifiedBadge,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    recommendationText ?? 
                        (language == 'fil' ? 'Inirerekomenda para sa iyo' : 'Recommended for You'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ColorConstant.verifiedBadge,
                    ),
                  ),
                ],
              ),
            ),
          
          // Facility content
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Facility icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ColorConstant.calmingBlue.withOpacity(0.15),
                              ColorConstant.calmingBlue.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          facility.typeIcon,
                          color: ColorConstant.calmingBlue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Facility info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    facility.name,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: ColorConstant.bluedark,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: ColorConstant.calmingBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ColorConstant.calmingBlue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_hospital_outlined,
                                    size: 12,
                                    color: ColorConstant.trustBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    facility.typeName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ColorConstant.trustBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 14),
                  
                  // Distance and availability
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.location_on,
                        label: facility.distanceText,
                        color: ColorConstant.gentleGray,
                      ),
                      if (facility.is24Hours)
                        _InfoChip(
                          icon: Icons.access_time,
                          label: language == 'fil' ? 'Bukas 24/7' : 'Open 24/7',
                          color: ColorConstant.reassuringGreen,
                          isBadge: true,
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: ColorConstant.gentleGray,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          facility.address,
                          style: TextStyle(
                            fontSize: 13,
                            color: ColorConstant.gentleGray,
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  // Notes/Description (if available)
                  if (facility.description != null && facility.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ColorConstant.warmBeige,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: ColorConstant.trustBlue,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              facility.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: ColorConstant.bluedark.withOpacity(0.9),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: ColorConstant.softWhite,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                if (onCall != null && facility.primaryContact != null)
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.phone_outlined,
                      label: language == 'fil' ? 'Tawagan' : 'Call',
                      color: ColorConstant.reassuringGreen,
                      onPressed: onCall!,
                      isPrimary: false,
                    ),
                  ),
                if (onCall != null && facility.primaryContact != null && onNavigate != null)
                  const SizedBox(width: 10),
                if (onNavigate != null)
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.directions_outlined,
                      label: language == 'fil' ? 'Pumunta' : 'Navigate',
                      color: ColorConstant.calmingBlue,
                      onPressed: onNavigate!,
                      isPrimary: true,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Info chip for facility details
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isBadge;
  
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    this.isBadge = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isBadge ? 10 : 8,
        vertical: isBadge ? 5 : 4,
      ),
      decoration: BoxDecoration(
        color: isBadge ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: isBadge ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Action button for facility cards
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isPrimary;
  
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    required this.isPrimary,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
    );
  }
}

/// Breadcrumb trail for navigation progress
class CarePathBreadcrumb extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  final String language;
  
  const CarePathBreadcrumb({
    Key? key,
    required this.steps,
    required this.currentStep,
    required this.language,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: ColorConstant.softWhite,
        border: Border(
          bottom: BorderSide(
            color: ColorConstant.cardBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.healing,
            size: 18,
            color: ColorConstant.calmingBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(steps.length * 2 - 1, (index) {
                  if (index.isOdd) {
                    // Separator
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: ColorConstant.gentleGray.withOpacity(0.5),
                      ),
                    );
                  }
                  
                  final stepIndex = index ~/ 2;
                  final isActive = stepIndex == currentStep;
                  final isCompleted = stepIndex < currentStep;
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? ColorConstant.calmingBlue
                          : isCompleted
                              ? ColorConstant.reassuringGreen.withOpacity(0.15)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? ColorConstant.calmingBlue
                            : isCompleted
                                ? ColorConstant.reassuringGreen
                                : ColorConstant.cardBorder,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      steps[stepIndex],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive
                            ? Colors.white
                            : isCompleted
                                ? ColorConstant.reassuringGreen
                                : ColorConstant.gentleGray,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Large, accessible button with icon
class LargeAccessibleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  
  const LargeAccessibleButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60, // Large tap target (56px minimum + padding)
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: backgroundColor,
                side: BorderSide(color: backgroundColor, width: 2.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _buildContent(),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                elevation: 2,
                shadowColor: backgroundColor.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _buildContent(),
            ),
    );
  }
  
  Widget _buildContent() {
    if (isLoading) {
      return SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          color: isOutlined ? backgroundColor : foregroundColor,
          strokeWidth: 3,
        ),
      );
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 26),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// Contextual filter chips
class FilterChipRow extends StatelessWidget {
  final List<String> filters;
  final int selectedIndex;
  final Function(int) onSelected;
  
  const FilterChipRow({
    Key? key,
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return FilterChip(
            label: Text(
              filters[index],
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(index),
            backgroundColor: ColorConstant.softWhite,
            selectedColor: ColorConstant.calmingBlue.withOpacity(0.15),
            checkmarkColor: ColorConstant.calmingBlue,
            side: BorderSide(
              color: isSelected
                  ? ColorConstant.calmingBlue
                  : ColorConstant.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          );
        },
      ),
    );
  }
}

