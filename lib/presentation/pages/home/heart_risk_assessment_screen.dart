import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/routes/app_routes.dart';
import 'package:juan_heart/themes/app_styles.dart';
import 'package:juan_heart/presentation/pages/home/medical_triage_assessment_screen.dart';

class HeartRiskAssessmentScreen extends StatefulWidget {
  const HeartRiskAssessmentScreen({super.key});

  @override
  State<HeartRiskAssessmentScreen> createState() => _HeartRiskAssessmentScreenState();
}

class _HeartRiskAssessmentScreenState extends State<HeartRiskAssessmentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.whiteBackground,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text(
          "Heart Risk Assessment",
          style: TextStyle(
            color: ColorConstant.bluedark,
            fontFamily: "Poppins",
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: ColorConstant.bluedark,
          ),
          onPressed: () {
            Get.back();
          },
        ),
        backgroundColor: ColorConstant.whiteBackground,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Heart icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: ColorConstant.bluedark.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.favorite,
                  size: 60,
                  color: ColorConstant.bluedark,
                ),
              ),
              const SizedBox(height: 30),
              
              // Title
              Text(
                "Medical Triage Assessment",
                style: AppStyle.txtPoppinsSemiBold24Dark,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                "Philippine Heart Center",
                style: TextStyle(
                  color: ColorConstant.bluedark.withOpacity(0.7),
                  fontSize: 18,
                  fontFamily: "Poppins",
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Description
              Text(
                "Assess your cardiovascular risk using medically validated scoring from Philippine Heart Center experts. This assessment uses likelihood and impact scoring to provide personalized recommendations.",
                style: TextStyle(
                  color: ColorConstant.bluedark.withOpacity(0.6),
                  fontSize: 14,
                  fontFamily: "Poppins",
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              // Data Privacy Statement
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorConstant.lightBlueBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorConstant.bluedark.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.privacy_tip_outlined,
                          color: ColorConstant.bluedark,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Data Privacy Notice",
                          style: TextStyle(
                            color: ColorConstant.bluedark,
                            fontSize: 16,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Your data will be used only for health analysis and risk assessment. No personal information will be stored or shared with third parties. This assessment complies with the Philippine Data Privacy Act (RA 10173).",
                      style: TextStyle(
                        color: ColorConstant.bluedark.withOpacity(0.8),
                        fontSize: 13,
                        fontFamily: "Poppins",
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Start Assessment Button
              ElevatedButton(
                onPressed: () {
                  Get.to(() => const MedicalTriageAssessmentScreen());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstant.bluedark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  "Start Assessment",
                  style: AppStyle.txtPoppinsSemiBold18Dark.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
