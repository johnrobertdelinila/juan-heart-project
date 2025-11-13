import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:juan_heart/bloc/home/get_user_data/fetch_bloc.dart';
import 'package:juan_heart/bloc/home/get_user_data/fetch_bloc_event.dart';
import 'package:juan_heart/bloc/home/get_user_data/fetch_bloc_state.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/models/user_model.dart';
import 'package:juan_heart/presentation/widgets/cached_image.dart';
import 'package:juan_heart/routes/app_routes.dart';
import 'package:juan_heart/themes/app_decoration.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';

class StrokeEmergencyScreen extends StatefulWidget {
  final UserModel? userModel;
  const StrokeEmergencyScreen({super.key, this.userModel});

  @override
  State<StrokeEmergencyScreen> createState() => _StrokeEmergencyScreenState();
}

class _StrokeEmergencyScreenState extends State<StrokeEmergencyScreen> {
  List listOfWhatToDo = [
    {
      "title": "Stay Calm, and wait for Ambulance. ",
      "description":
          "Do not panic. If you have called an ambulance, wait for help to arrive. Do not attempt to drive.",
    },
    {
      "title": "Do not lose conciousness",
      "description":
          "Try to stay awake. If you believe you are losing consciousness, take an aspirin. Try keeping your eyes open.",
    },
    {
      "title": "Importance of CPR ",
      "description":
          "If you are not alone and there is someone to assist you, ask them to perform CPR if your vitals are dropping.",
    },
    {
      "title": "Check for Symprtoms: ",
      "description":
          "Face: If your face is drooping.\n Arm: If your arms feel weak.\nSpeech: Speech difficulties. Then it is Time to call an Ambulance",
    },
  ];

  late FetchUserDataBloc fetchUserDataBloc;

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  TwilioFlutter twilioFlutter = TwilioFlutter(
      accountSid: dotenv.env['ACCOUNT_SID'] ?? '',
      authToken: dotenv.env['AUTH_TOKEN'] ?? '',
      twilioNumber: dotenv.env['TWILIO_NUMBER'] ?? '');

  void sendSoS() async {
    Position position = await _determinePosition();

    String emergencyContactNumber1 = "+919177114722";

    String location =
        'Their location: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

    twilioFlutter.sendSMS(
        toNumber: emergencyContactNumber1,
        messageBody:
            'SOS! Emergency alert from team healthify.\n$userName might be suffering from a heart Stroke.\n $location');
  }

  @override
  void initState() {
    super.initState();

    fetchUserDataBloc = FetchUserDataBloc();
    fetchUserDataBloc.add(const GetUserData());
  }

  String userName = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.whiteBackground,
      appBar: AppBar(
        backgroundColor: ColorConstant.whiteBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorConstant.bluedark),
          onPressed: () => Get.toNamed(AppRoutes.home),
        ),
        title: Text(
          "stroke".tr,
          style: JHTextStyles.h4.copyWith(
            color: ColorConstant.bluedark,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.more_horiz,
              color: ColorConstant.bluedark,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.only(
            left: 22,
            right: 22,
            bottom: 40,
          ),
          child: BlocProvider(
            create: (_) => fetchUserDataBloc,
            child: BlocListener<FetchUserDataBloc, FetchUserDataBlocState>(
              listener: (context, state) {
                if (state is FetchingDataSuccess) {
                  setState(() {
                    userName = state.user.fullName!;
                  });
                }
              },
              child: Column(
                children: [
                  _dailyActivityNotification(
                    false,
                    "An alert has been sent to your emergency contact.",
                  ),
                  CallAnAmbulance(onTap: () {
                    sendSoS();
                  }),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 25.0,
                      bottom: 25,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "whatToDo".tr,
                          style: JHTextStyles.h5.copyWith(color: ColorConstant.bluedark),
                        ),
                        Text(
                          "4 Steps",
                          style: JHTextStyles.bodySmall.copyWith(
                            color: ColorConstant.bluedark.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  WhatToDoWidget(
                    title: listOfWhatToDo[0]["title"],
                    index: "01",
                    description: listOfWhatToDo[0]["description"],
                  ),
                  WhatToDoWidget(
                    title: listOfWhatToDo[1]["title"],
                    index: "02",
                    description: listOfWhatToDo[1]["description"],
                  ),
                  WhatToDoWidget(
                    title: listOfWhatToDo[2]["title"],
                    index: "03",
                    description: listOfWhatToDo[2]["description"],
                  ),
                  WhatToDoWidget(
                    title: listOfWhatToDo[3]["title"],
                    index: "04",
                    description: listOfWhatToDo[3]["description"],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dailyActivityNotification(bool isAlertNotification, String message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 22),
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          Icon(
            Icons.info_rounded,
            color: isAlertNotification
                ? ColorConstant.lightRed
                : ColorConstant.warningColor,
            size: 26,
          ),
          const SizedBox(
            width: 10,
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.75,
            child: Text(
              message,
              style: JHTextStyles.bodySmall.copyWith(color: ColorConstant.bluedark.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class CallAnAmbulance extends StatelessWidget {
  final VoidCallback onTap;
  const CallAnAmbulance({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        width: MediaQuery.of(context).size.width * 0.7,
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: ColorConstant.lightRed,
          ),
          borderRadius: BorderRadiusStyle.roundedBorder15,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CachedIconImage(
              assetPath: ImageConstant.iconAlert,
              size: 30,
            ),
            const SizedBox(
              width: 22,
            ),
            Text(
              "callAmb".tr,
              style: JHTextStyles.button.copyWith(
                color: ColorConstant.lightRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WhatToDoWidget extends StatelessWidget {
  final String title, description, index;
  const WhatToDoWidget(
      {super.key,
      required this.title,
      required this.description,
      required this.index});

  Widget _dotline() {
    return Container(
      margin: const EdgeInsets.only(left: 14, top: 5),
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: ColorConstant.bluedark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                        index,
                        style: JHTextStyles.h5.copyWith(color: ColorConstant.bluedark.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      Icon(
                        Icons.adjust_sharp,
                        color: ColorConstant.bluedark.withValues(alpha: 0.8),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                  _dotline(),
                  _dotline(),
                  _dotline(),
                  _dotline(),
                  _dotline(),
                  _dotline(),
                  _dotline(),
                  _dotline(),
                  _dotline(),
                  _dotline(),
                  _dotline(),
                ],
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 1.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: JHTextStyles.bodyBase.copyWith(color: ColorConstant.bluedark, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      description,
                      style: JHTextStyles.bodySmall.copyWith(
                        color: ColorConstant.bluedark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
