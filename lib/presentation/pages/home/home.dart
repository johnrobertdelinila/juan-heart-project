import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:juan_heart/bloc/home/get_user_data/fetch_bloc.dart';
import 'package:juan_heart/bloc/home/get_user_data/fetch_bloc_event.dart';
import 'package:juan_heart/bloc/home/get_user_data/fetch_bloc_state.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/presentation/pages/home/home_screen.dart';
import 'package:juan_heart/presentation/pages/home/appointments_screen.dart';
import 'package:juan_heart/presentation/pages/home/user_profile_screen.dart';
import 'package:juan_heart/routes/app_routes.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../widgets/custom_bottom_navigation_bar.dart';
import 'analytics_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int activeIndex = 0;

  // GlobalKey to access AppointmentsScreen state
  final _appointmentsKey = GlobalKey<State<AppointmentsScreen>>();

  late List<Widget> screens;

  // Store success data for showing dialog after navigation
  Map<String, dynamic>? _successData;

  @override
  void initState() {
    super.initState();

    // Check if initial tab is specified in navigation arguments
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args['initialTab'] != null) {
        activeIndex = args['initialTab'] as int;
      }

      // Check if we need to show success dialog
      if (args['showSuccessDialog'] == true && args['appointmentData'] != null) {
        _successData = args['appointmentData'] as Map<String, dynamic>;
      }
    }

    screens = [
      HomeScreen(),
      const AnalyticsScreen(),
      AppointmentsScreen(key: _appointmentsKey),
      const UserProfileScreen(),
    ];
    fetchUserDataBloc = FetchUserDataBloc();
    fetchUserDataBloc.add(const GetUserData());
  }

  String userName = "";
  late FetchUserDataBloc fetchUserDataBloc;

  TwilioFlutter twilioFlutter = TwilioFlutter(
      accountSid: dotenv.env['ACCOUNT_SID'] ?? '',
      authToken: dotenv.env['AUTH_TOKEN'] ?? '',
      twilioNumber: dotenv.env['TWILIO_NUMBER'] ?? '');

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

  void sendSoS() async {
    Position position = await _determinePosition();

    String emergencyContactNumber1 = "+918688668145";

    String location =
        'Their location: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

    twilioFlutter.sendSMS(
        toNumber: emergencyContactNumber1,
        messageBody:
            'SOS! Emergency alert from team healthify.\n$userName might be suffering from a heart Stroke.\n $location');
  }

  void _showCustomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SizedBox(
            height: 250,
            width: MediaQuery.of(context).size.width,
            child: Container(
              height: 150,
              width: MediaQuery.of(context).size.width,
              color: Colors.transparent,
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: 100,
                        color: Colors.transparent,
                      ),
                      Positioned(
                        width: MediaQuery.of(context).size.width,
                        bottom: -10,
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 50,
                          color: ColorConstant.whiteBackground,
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.only(
                            left: 22,
                            right: 22,
                            bottom: 22,
                            top: 30,
                          ),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: ColorConstant.lightRed,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Center(
                            child: Image.asset(
                              ImageConstant.imgHealthify,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 150,
                    decoration: BoxDecoration(
                      color: ColorConstant.whiteBackground,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(
                            left: 35,
                          ),
                          child: Text(
                            "Take a Heart Risk Assessment?",
                            style: TextStyle(
                              color: ColorConstant.bluedark,
                              fontSize: 15,
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 30.0, left: 15, right: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SosButton(
                                title: "Start",
                                onTap: () {
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.pop(context); // close dialog
                                    Get.toNamed(AppRoutes.heartRiskAssessmentScreen);
                                  }
                                },
                              ),
                              SosButton(
                                title: "Not Now",
                                enableOutlineButton: true,
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBookingSuccessDialog(BuildContext context, Map<String, dynamic> data) {
    final isFilipino = Get.locale?.languageCode == 'fil';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isFilipino ? 'Tagumpay!' : 'Success!',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFilipino
                  ? 'Ang inyong appointment ay matagumpay na na-book!'
                  : 'Your appointment has been booked successfully!',
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.local_hospital,
                    isFilipino ? 'Pasilidad' : 'Facility',
                    data['facilityName'] ?? 'N/A',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.calendar_today,
                    isFilipino ? 'Petsa' : 'Date',
                    data['date'] ?? 'N/A',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.access_time,
                    isFilipino ? 'Oras' : 'Time',
                    data['time'] ?? 'N/A',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.medical_services,
                    isFilipino ? 'Uri' : 'Type',
                    data['type'] ?? 'N/A',
                  ),
                  if (data['hasAssessment'] == true) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.assignment_turned_in, size: 16, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isFilipino
                                  ? 'May kasamang assessment data'
                                  : 'Includes assessment data',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[900],
                                fontWeight: FontWeight.w500,
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
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstant.lightRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              isFilipino ? 'OK' : 'OK',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show success dialog after frame renders if data is available
    if (_successData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showBookingSuccessDialog(context, _successData!);
        setState(() {
          _successData = null; // Clear after showing
        });
      });
    }

    return Scaffold(
      body: BlocProvider(
        create: (_) => fetchUserDataBloc,
        child: BlocListener<FetchUserDataBloc, FetchUserDataBlocState>(
          listener: (context, state) {
            if (state is FetchingDataSuccess) {
              setState(() {
                userName = state.user.fullName!;
              });
            }
          },
          child: screens[activeIndex],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        activeIndex: activeIndex,
        onPressHome: () {
          setState(() {
            activeIndex = 0;
          });
        },
        onPressPieChart: () {
          setState(() {
            activeIndex = 1;
          });
        },
        onPressSOS: () {
          _showCustomDialog(context);
        },
        onPressAppointments: () {
          setState(() {
            activeIndex = 2;
          });
          // Refresh appointments when tab is pressed
          final state = _appointmentsKey.currentState;
          if (state != null) {
            (state as dynamic).refreshAppointments();
          }
        },
        onPressProfile: () {
          setState(() {
            activeIndex = 3;
          });
        },
      ),
    );
  }
}

class SosButton extends StatelessWidget {
  final String title;
  final bool? enableOutlineButton;

  final VoidCallback onTap;

  const SosButton(
      {super.key,
      required this.title,
      this.enableOutlineButton = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        decoration: BoxDecoration(
          color: enableOutlineButton == true
              ? Colors.transparent
              : ColorConstant.lightRed,
          border: Border.all(
            width: 2,
            color: ColorConstant.lightRed,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: enableOutlineButton == true
                ? ColorConstant.lightRed
                : ColorConstant.whiteText,
            fontFamily: "Poppins",
          ),
        ),
      ),
    );
  }
}
