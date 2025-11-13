import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:juan_heart/bloc/auth_bloc/signup_bloc/signup_bloc.dart';
import 'package:juan_heart/bloc/auth_bloc/signup_bloc/signup_bloc_state.dart';
import 'package:juan_heart/routes/app_routes.dart';
import 'package:juan_heart/service/ApiService.dart';
import 'package:juan_heart/themes/app_decoration.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';
import 'package:juan_heart/presentation/widgets/cached_image.dart';

import '../../../core/app_exports.dart';
import '../../widgets/export_widgets.dart';

class SignUpScreen extends StatefulWidget {
  final apiService = ApiService();
  SignUpScreen({
    super.key,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _passwordVisible = true;
  bool isKeyboardActive = false;

  final FocusNode _fullNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late SignUpBloc _signUpBloc;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() {
        isKeyboardActive = !isKeyboardActive;
      });
    });

    _passwordFocusNode.addListener(() {
      setState(() {
        isKeyboardActive = !isKeyboardActive;
      });
    });

    _fullNameFocusNode.addListener(() {
      setState(() {
        isKeyboardActive = !isKeyboardActive;
      });
    });

    _signUpBloc = SignUpBloc(apiService: widget.apiService);
  }

  @override
  void dispose() {
    // Dispose controllers
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    // Dispose focus nodes
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    // Close BLoC
    _signUpBloc.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SignUpBloc, SignUpState>(
        bloc: _signUpBloc,
        builder: (context, state) {
          if (state is SignUpLoading) {
            return Container(
              color: JHColors.midnightBlue,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Center(
                child: CircularProgressIndicator(
                  color: JHColors.cloudWhite,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height,
              color: JHColors.softGray,
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: isKeyboardActive
                        ? MediaQuery.of(context).size.height / 3
                        : MediaQuery.of(context).size.height / 2,
                    decoration:
                        AppDecoration.fillIndigoWithBorderRadiusBottomLR22,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: CachedImage.asset(
                        ImageConstant.imgLogoDark,
                        fit: BoxFit.contain,
                        cacheHeight: 400,
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    top: isKeyboardActive
                        ? 50
                        : MediaQuery.of(context).size.height / 3,
                    left: 20,
                    right: 20,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 450,
                      decoration:
                          AppDecoration.fillWhiteWithBorderRadiusAndBoxShadow,
                      child: Column(
                        children: [
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              "Sign Up",
                              style: JHTextStyles.h3.copyWith(
                                color: JHColors.midnightBlue,
                              ),
                            ),
                          ),
                          _fullNameCustomTextField(),
                          _emailCustomTextField(),
                          _passwordCustomTextField(),
                          CustomTextButton(
                            onTap: () {
                              // final userModel = UserModel(
                              //   fullName: _fullNameController.text,
                              //   email: _emailController.text,
                              //   password: _passwordController.text,
                              // );

                              // if (userModel.email.isNotEmpty &&
                              //     userModel.fullName.isNotEmpty &&
                              //     userModel.password.isNotEmpty) {
                              //   _signUpBloc.add(
                              //       SignUpButtonPressed(userModel: userModel));

                              //   if (state is SignUpFailure) {
                              //     ScaffoldMessenger.of(context).showSnackBar(
                              //       SnackBar(
                              //         content: Text(state.errorMessage),
                              //         duration:
                              //             const Duration(milliseconds: 800),
                              //       ),
                              //     );
                              //   } else {
                              //     // after user get authenticated navigate to next screen
                              //     Get.toNamed(AppRoutes.userDetailsScreen);
                              //   }
                              // } else {
                              //   ScaffoldMessenger.of(context).showSnackBar(
                              //     const SnackBar(
                              //       content:
                              //           Text("Please enter all the fields"),
                              //       duration: Duration(milliseconds: 800),
                              //     ),
                              //   );
                              // }
                            },
                            label: "Sign Up",
                            labelColor: JHColors.cloudWhite,
                            buttonBgColor: JHColors.midnightBlue,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: MediaQuery.of(context).size.height / 20,
                    left: 22,
                    right: 22,
                    child: FocusScope(
                      autofocus: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account?",
                            style: JHTextStyles.bodyLarge.copyWith(
                              color: ColorConstant.bluegray9006c,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          TextWithGestureDetector(
                            text: "Sign In",
                            onTap: () {
                              Get.toNamed(AppRoutes.signInScreen);
                            },
                            textStyle: JHTextStyles.h5.copyWith(
                              color: ColorConstant.bluedark.withValues(alpha: 0.8),
                              fontSize: 17,
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _fullNameCustomTextField() {
    return CustomTextFormField(
      controller: _fullNameController,
      margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      keyboardType: TextInputType.text,
      hintText: "Full Name",
      focusNode: _fullNameFocusNode,
      prefixIcon: const Icon(
        Icons.person,
      ),
    );
  }

  Widget _emailCustomTextField() {
    return CustomTextFormField(
      controller: _emailController,
      margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      keyboardType: TextInputType.emailAddress,
      hintText: "Email",
      focusNode: _emailFocusNode,
      prefixIcon: const Icon(
        Icons.email,
      ),
    );
  }

  Widget _passwordCustomTextField() {
    return CustomTextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      hintText: "Password",
      prefixIcon: const Icon(
        Icons.lock,
      ),
      isObscureText: _passwordVisible,
      suffixIcon: IconButton(
        onPressed: () {
          setState(() {
            _passwordVisible = !_passwordVisible;
          });
        },
        icon: Icon(
          _passwordVisible ? Icons.visibility_off : Icons.visibility,
          size: 22,
          color: _passwordVisible
              ? ColorConstant.bluedark.withValues(alpha: 0.3)
              : ColorConstant.bluedark,
        ),
      ),
    );
  }
}
