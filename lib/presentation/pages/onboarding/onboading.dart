// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:juan_heart/themes/app_styles.dart';
import 'package:juan_heart/routes/app_routes.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:juan_heart/presentation/pages/home/home.dart';

import 'data/constants/slider_modal_data.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  int currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          LiquidSwipe(
            pages: [
              SliderScreen(
                pageIndex: 0,
                backgroundColor: Colors.white,
              ),
              SliderScreen(
                pageIndex: 1,
                backgroundColor: Color.fromARGB(255, 102, 191, 251),
              ),
              SliderScreen(
                pageIndex: 2,
                backgroundColor: Color.fromARGB(255, 249, 95, 146),
              ),
              SliderScreen(
                pageIndex: 3,
                backgroundColor: Color.fromARGB(255, 250, 144, 83),
              ),
            ],
            slideIconWidget: const Icon(Icons.arrow_back_ios),
            enableLoop: false,
            enableSideReveal: true,
            onPageChangeCallback: (page) {
              setState(() {
                currentPage = page;
              });
            },
          ),
          // Circle indicators (only show on first 3 pages)
          if (currentPage < 3)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: _buildPageIndicators(),
            ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: currentPage == index ? 8 : 6,
          height: currentPage == index ? 8 : 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentPage == index 
                ? Colors.white 
                : Colors.white.withOpacity(0.6),
            border: Border.all(
              color: currentPage == index 
                  ? Colors.grey[600]! 
                  : Colors.grey[400]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class SliderScreen extends StatelessWidget {
  final int pageIndex;
  final Color backgroundColor;
  const SliderScreen({
    Key? key,
    required this.pageIndex,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
      color: backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              SizedBox(
                height: 400,
                child: Image.asset(SliderModalContant.onBoadingData[pageIndex]
                    ["assetImagePath"]),
              ),
              Column(
                children: [
                  Text(
                    SliderModalContant.onBoadingData[pageIndex]["title"],
                    style: AppStyle.txtDMSanBold27,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    SliderModalContant.onBoadingData[pageIndex]["description"],
                    style: AppStyle.txtPoppinsSemiBold18Light,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
          pageIndex != 3
              ? const SizedBox(height: 40) // Space for circle indicators
              : GestureDetector(
                  onTap: () {
                    // Temporarily bypass login screen - go directly to home
                    print('Get Started button pressed');
                    print('Navigating to Home screen');
                    Get.offAll(() => const Home());
                  },
                  child: Container(
                    width: 200,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Get Started',
                        style: AppStyle.txtPoppinsBold18Dark,
                      ),
                    ),
                  ),
                )
        ],
      ),
    );
  }
}
