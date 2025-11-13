import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:juan_heart/bloc/auth_bloc/form_submission_status.dart';
import 'package:juan_heart/bloc/auth_bloc/signin_bloc/signin_bloc.dart';
import 'package:juan_heart/bloc/auth_bloc/signin_bloc/signin_bloc_event.dart';
import 'package:juan_heart/bloc/auth_bloc/signin_bloc/signin_bloc_state.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/presentation/pages/home/home.dart';
import 'package:juan_heart/repository/auth_repo/auth_repository.dart';
import 'package:juan_heart/routes/app_routes.dart';
import 'package:juan_heart/themes/app_decoration.dart';
import 'package:juan_heart/presentation/widgets/cached_image.dart';

import 'package:juan_heart/themes/jh_text_styles.dart';
import '../../widgets/export_widgets.dart';

class SignInScreen extends StatefulWidget {
  // final apiService = ApiService();
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _passwordVisible = true;

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isKeyboardActive = false;

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
  }

  @override
  void dispose() {
    // Dispose controllers
    _emailController.dispose();
    _passwordController.dispose();

    // Dispose focus nodes
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => SignInBloc(
          authRepo: context.read<AuthRepository>(),
        ),
        child: _loginScreen(),
      ),
    );
  }

  Widget _loginScreen() {
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
                  ? MediaQuery.of(context).size.height / 2.5
                  : MediaQuery.of(context).size.height / 2,
              decoration: AppDecoration.fillIndigoWithBorderRadiusBottomLR22,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: CachedImage.asset(
                  ImageConstant.imgLogoDark,
                  fit: BoxFit.contain,
                  cacheHeight: 400, // Optimize for typical screen height
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: isKeyboardActive
                  ? 70
                  : MediaQuery.of(context).size.height / 3,
              left: 20,
              right: 20,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 400,
                decoration: AppDecoration.fillWhiteWithBorderRadiusAndBoxShadow,
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "Sign In",
                        style: JHTextStyles.h3.copyWith(
                          color: ColorConstant.bluedark,
                        ),
                      ),
                    ),
                    _emailCustomTextField(),
                    _passwordCustomTextField(),
                    BlocBuilder<SignInBloc, SignInBlocState>(
                      builder: (context, state) {
                        return state.formStatus is FormSubmitting
                            ? const CircularProgressIndicator()
                            : CustomTextButton(
                                onTap: () async {
                                  if (_emailController.text.isNotEmpty &&
                                      _passwordController.text.isNotEmpty) {
                                    context
                                        .read<SignInBloc>()
                                        .add(SignInSubmitted());

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const Home(),
                                      ),
                                    );

                                    if (state is SubmissionFailed) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Center(
                                            child: Text("Failed to login"),
                                          ),
                                          duration: Duration(milliseconds: 800),
                                        ),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Center(
                                          child: Text(
                                              "Please enter all the fields"),
                                        ),
                                        duration: Duration(milliseconds: 800),
                                      ),
                                    );
                                  }
                                },
                                label: "Sign In",
                                labelColor: JHColors.cloudWhite,
                                buttonBgColor: JHColors.midnightBlue,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 15,
                                ),
                              );
                      },
                    ),
                    TextWithGestureDetector(
                      text: "Forget Password?",
                      onTap: () {},
                      textStyle: JHTextStyles.h5.copyWith(
                        color: JHColors.midnightBlue.withValues(alpha: 0.8),
                        fontSize: 17,
                      ),
                    )
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
                      "Don't have an account?",
                      style: JHTextStyles.bodyLarge.copyWith(
                        color: ColorConstant.bluegray9006c,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    TextWithGestureDetector(
                      text: "Register",
                      onTap: () {
                        Get.toNamed(AppRoutes.signUpScreen);
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
  }

  Widget _emailCustomTextField() {
    return BlocBuilder<SignInBloc, SignInBlocState>(
      builder: (context, state) {
        return CustomTextFormField(
          onChanged: (value) => context.read<SignInBloc>().add(
                SignInEmail(email: value),
              ),
          controller: _emailController,
          margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          keyboardType: TextInputType.emailAddress,
          hintText: "Email",
          focusNode: _emailFocusNode,
          prefixIcon: const Icon(
            Icons.email,
          ),
        );
      },
    );
  }

  Widget _passwordCustomTextField() {
    return BlocBuilder<SignInBloc, SignInBlocState>(
      builder: (context, state) {
        return CustomTextFormField(
          onChanged: (value) =>
              context.read<SignInBloc>().add(SignInPassword(password: value)),
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
      },
    );
  }
}
