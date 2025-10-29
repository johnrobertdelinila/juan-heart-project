/// Enhanced UI Components for Heart Assessment Feature
/// 
/// Provides conversational, guided, and emotionally intelligent
/// assessment experience aligned with the referral system design
///
/// Design Philosophy:
/// - Conversational and warm, not clinical
/// - Progressive disclosure with visual feedback
/// - Bilingual Taglish support
/// - Accessibility-first approach
/// - Seamless integration with referral system

import 'package:flutter/material.dart';
import 'package:juan_heart/core/utils/color_constants.dart';

/// Animated heart logo for welcome and loading states
class AnimatedHeartLogo extends StatefulWidget {
  final double size;
  final Color color;
  
  const AnimatedHeartLogo({
    Key? key,
    this.size = 120,
    this.color = const Color(0xFFE63946),
  }) : super(key: key);
  
  @override
  State<AnimatedHeartLogo> createState() => _AnimatedHeartLogoState();
}

class _AnimatedHeartLogoState extends State<AnimatedHeartLogo> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
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
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}

/// Assessment welcome card with conversational design
class AssessmentWelcomeCard extends StatelessWidget {
  final String userName;
  final String language;
  final VoidCallback onStart;
  
  const AssessmentWelcomeCard({
    Key? key,
    required this.userName,
    required this.language,
    required this.onStart,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE0F2FE),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated heart
          const AnimatedHeartLogo(size: 100, color: Color(0xFFE63946)),
          
          const SizedBox(height: 32),
          
          // Personalized greeting
          Text(
            language == 'fil' 
                ? 'Hi${userName.isNotEmpty ? " $userName" : ""}! Tingnan natin ang kalusugan ng puso mo.'
                : 'Hi${userName.isNotEmpty ? " $userName" : ""}! Let\'s check your heart health.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212529),
              height: 1.3,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Subtext
          Text(
            language == 'fil'
                ? 'Sagutan ang ilang mabilis na tanong para malaman ang iyong heart risk. Tatagal lang ng 2 minuto.'
                : 'Answer a few quick questions to assess your heart risk. It\'ll take less than 2 minutes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: ColorConstant.gentleGray,
              height: 1.6,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Start button with pulse animation
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E5BBA),
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: const Color(0xFF2E5BBA).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    language == 'fil' ? 'Simulan ang Assessment' : 'Start Assessment',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Privacy note
          _buildPrivacyNote(language),
        ],
      ),
    );
  }
  
  Widget _buildPrivacyNote(String language) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstant.warmBeige,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstant.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            size: 20,
            color: ColorConstant.trustBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              language == 'fil'
                  ? 'Ang iyong data ay ligtas at private. Hindi ito ibabahagi.'
                  : 'Your data is safe and private. We don\'t share your information.',
              style: TextStyle(
                fontSize: 12,
                color: ColorConstant.bluedark.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress indicator with encouraging messages
class AssessmentProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String language;
  
  const AssessmentProgressIndicator({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.language,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;
    final stepText = language == 'fil' 
        ? 'Hakbang $currentStep ng $totalSteps'
        : 'Step $currentStep of $totalSteps';
    
    String encouragement = '';
    if (currentStep == 1) {
      encouragement = language == 'fil' ? 'Nagsisimula pa lang!' : 'Just getting started!';
    } else if (currentStep == totalSteps ~/ 2) {
      encouragement = language == 'fil' ? 'Kalahati na! Magaling!' : 'Halfway there! Great job!';
    } else if (currentStep == totalSteps - 1) {
      encouragement = language == 'fil' ? 'Halos tapos na!' : 'Almost done!';
    } else if (currentStep > 1) {
      encouragement = language == 'fil' ? 'Mahusay!' : 'You\'re doing great!';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: ColorConstant.cardBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stepText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorConstant.bluedark,
                ),
              ),
              if (encouragement.isNotEmpty)
                Text(
                  encouragement,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: ColorConstant.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF2E5BBA),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Question card with smooth transitions
class QuestionCard extends StatelessWidget {
  final String question;
  final String? hint;
  final Widget child;
  final String? emoji;
  
  const QuestionCard({
    Key? key,
    required this.question,
    this.hint,
    required this.child,
    this.emoji,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(
              emoji!,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            question,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212529),
              height: 1.3,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 12),
            Text(
              hint!,
              style: TextStyle(
                fontSize: 14,
                color: ColorConstant.gentleGray,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

/// Toggle chip for yes/no questions
class ToggleChipGroup extends StatelessWidget {
  final List<String> options;
  final List<String> optionsValues;
  final String? selectedValue;
  final Function(String) onSelected;
  final Color? activeColor;
  
  const ToggleChipGroup({
    Key? key,
    required this.options,
    required this.optionsValues,
    this.selectedValue,
    required this.onSelected,
    this.activeColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(options.length, (index) {
        final isSelected = selectedValue == optionsValues[index];
        final color = activeColor ?? const Color(0xFF2E5BBA);
        
        return InkWell(
          onTap: () => onSelected(optionsValues[index]),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : ColorConstant.cardBorder,
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              options[index],
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : ColorConstant.bluedark,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Segmented control for gender/type selection
class SegmentedControl extends StatelessWidget {
  final List<String> options;
  final List<IconData>? icons;
  final int selectedIndex;
  final Function(int) onSelected;
  
  const SegmentedControl({
    Key? key,
    required this.options,
    this.icons,
    required this.selectedIndex,
    required this.onSelected,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConstant.softWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ColorConstant.cardBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        children: List.generate(options.length, (index) {
          final isSelected = index == selectedIndex;
          final isFirst = index == 0;
          final isLast = index == options.length - 1;
          
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.horizontal(
                left: isFirst ? const Radius.circular(12) : Radius.zero,
                right: isLast ? const Radius.circular(12) : Radius.zero,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2E5BBA) : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: isFirst ? const Radius.circular(12) : Radius.zero,
                    right: isLast ? const Radius.circular(12) : Radius.zero,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icons != null)
                      Icon(
                        icons![index],
                        color: isSelected ? Colors.white : ColorConstant.gentleGray,
                        size: 28,
                      ),
                    if (icons != null) const SizedBox(height: 8),
                    Text(
                      options[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : ColorConstant.bluedark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Enhanced text input with validation
class AssessmentTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? unit;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool showValidation;
  
  const AssessmentTextField({
    Key? key,
    required this.label,
    this.hint,
    this.unit,
    required this.controller,
    this.keyboardType = TextInputType.number,
    this.validator,
    this.showValidation = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final errorText = showValidation && validator != null && controller.text.isNotEmpty
        ? validator!(controller.text) 
        : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212529),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null 
                  ? const Color(0xFFE63946)
                  : ColorConstant.cardBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212529),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: ColorConstant.gentleGray,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              if (unit != null)
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text(
                    unit!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: ColorConstant.gentleGray,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 16,
                color: Color(0xFFE63946),
              ),
              const SizedBox(width: 6),
              Text(
                errorText,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFE63946),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Milestone completion feedback
class MilestoneFeedback extends StatelessWidget {
  final String message;
  final IconData icon;
  final String language;
  
  const MilestoneFeedback({
    Key? key,
    required this.message,
    required this.icon,
    required this.language,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withOpacity(0.15),
            const Color(0xFF4CAF50).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4CAF50),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212529),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary review card for confirmation screen
class SummaryReviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<MapEntry<String, String>> items;
  final VoidCallback onEdit;
  final String language;
  
  const SummaryReviewCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.items,
    required this.onEdit,
    required this.language,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConstant.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E5BBA).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF2E5BBA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212529),
                  ),
                ),
              ),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: const Color(0xFF2E5BBA),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        language == 'fil' ? 'I-edit' : 'Edit',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E5BBA),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.key,
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorConstant.gentleGray,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212529),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

/// Analyzing animation for results
class AnalyzingAnimation extends StatelessWidget {
  final String language;
  
  const AnalyzingAnimation({
    Key? key,
    required this.language,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ECG-style wave animation
          const AnimatedHeartLogo(size: 80, color: Color(0xFFE63946)),
          
          const SizedBox(height: 32),
          
          Text(
            language == 'fil' 
                ? 'Sinusuri ang iyong resulta...'
                : 'Analyzing your results...',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212529),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            language == 'fil'
                ? 'Sandali lang po, nag-aayos kami ng iyong heart risk score'
                : 'Just a moment, we\'re calculating your heart risk score',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: ColorConstant.gentleGray,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 32),
          
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E5BBA)),
            strokeWidth: 3,
          ),
        ],
      ),
    );
  }
}

/// Expandable symptom card for detailed symptom collection
class ExpandableSymptomCard extends StatefulWidget {
  final String symptomName;
  final String symptomDescription;
  final IconData icon;
  final bool isSelected;
  final Widget detailsWidget;
  final Function(bool) onExpanded;
  
  const ExpandableSymptomCard({
    Key? key,
    required this.symptomName,
    required this.symptomDescription,
    required this.icon,
    required this.isSelected,
    required this.detailsWidget,
    required this.onExpanded,
  }) : super(key: key);
  
  @override
  State<ExpandableSymptomCard> createState() => _ExpandableSymptomCardState();
}

class _ExpandableSymptomCardState extends State<ExpandableSymptomCard> 
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        widget.onExpanded(true);
      } else {
        _animationController.reverse();
        widget.onExpanded(false);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isSelected 
            ? const Color(0xFF2E5BBA).withOpacity(0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isSelected
              ? const Color(0xFF2E5BBA)
              : ColorConstant.cardBorder,
          width: widget.isSelected ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? const Color(0xFF2E5BBA).withOpacity(0.15)
                          : ColorConstant.softWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.isSelected
                          ? const Color(0xFF2E5BBA)
                          : ColorConstant.gentleGray,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.symptomName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.isSelected
                                ? const Color(0xFF2E5BBA)
                                : const Color(0xFF212529),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.symptomDescription,
                          style: TextStyle(
                            fontSize: 13,
                            color: ColorConstant.gentleGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: widget.isSelected
                          ? const Color(0xFF2E5BBA)
                          : ColorConstant.gentleGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Container(),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(
                    color: ColorConstant.cardBorder,
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                  widget.detailsWidget,
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// Range indicator for vital signs
class VitalRangeIndicator extends StatelessWidget {
  final String label;
  final double? value;
  final double minNormal;
  final double maxNormal;
  final double minRange;
  final double maxRange;
  final String unit;
  final Color? normalColor;
  final Color? warningColor;
  final Color? dangerColor;
  
  const VitalRangeIndicator({
    Key? key,
    required this.label,
    this.value,
    required this.minNormal,
    required this.maxNormal,
    required this.minRange,
    required this.maxRange,
    required this.unit,
    this.normalColor,
    this.warningColor,
    this.dangerColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final normal = normalColor ?? const Color(0xFF4CAF50);
    final warning = warningColor ?? const Color(0xFFFFA726);
    final danger = dangerColor ?? const Color(0xFFE63946);
    
    Color getColor() {
      if (value == null) return ColorConstant.gentleGray;
      if (value! < minNormal || value! > maxNormal) {
        if (value! < minRange || value! > maxRange) {
          return danger;
        }
        return warning;
      }
      return normal;
    }
    
    String getStatus() {
      if (value == null) return 'Not entered';
      if (value! < minNormal || value! > maxNormal) {
        if (value! < minRange || value! > maxRange) {
          return 'Outside safe range';
        }
        return 'Outside normal range';
      }
      return 'Normal';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getColor().withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getColor().withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212529),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: getColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      value == null
                          ? Icons.remove_circle_outline
                          : (value! >= minNormal && value! <= maxNormal)
                              ? Icons.check_circle
                              : Icons.warning,
                      size: 14,
                      color: getColor(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      getStatus(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: getColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (value != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value!.toStringAsFixed(value! % 1 == 0 ? 0 : 1),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: getColor(),
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: getColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Normal range: $minNormal-$maxNormal $unit',
              style: TextStyle(
                fontSize: 12,
                color: ColorConstant.gentleGray,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Large action button with icon
class LargeActionButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;
  final bool isSecondary;
  
  const LargeActionButton({
    Key? key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    this.isSecondary = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? 
        (isSecondary ? ColorConstant.softWhite : const Color(0xFF2E5BBA));
    final fgColor = foregroundColor ?? 
        (isSecondary ? const Color(0xFF212529) : Colors.white);
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: isSecondary ? 0 : 2,
          shadowColor: bgColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isSecondary
                ? BorderSide(color: ColorConstant.cardBorder, width: 2)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 24),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

