import 'package:call_detector/data/response/status.dart';
import 'package:call_detector/res/components/buttons/custom_button.dart';
import 'package:call_detector/res/components/field/custom_textformfield.dart';
import 'package:call_detector/res/components/text/headline_large_text.dart';
import 'package:call_detector/res/components/text/label_large_text.dart';
import 'package:call_detector/view/home/home_view.dart';
import 'package:call_detector/viewmodel/login/login_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<LoginView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final _fomrKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _animationController.forward();
    super.initState();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final viewmodel = ref.read(loginViewmodelProvider.notifier);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    height: size.height - MediaQuery.of(context).padding.top,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Form(
                      key: _fomrKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primary.withValues(alpha: 0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(35),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 25,
                                  offset: const Offset(0, 15),
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 40,
                                  offset: const Offset(0, 5),
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.business_center_rounded,
                              size: 70,
                              color: colorScheme.onPrimary,
                            ),
                          ),

                          const Gap(32),
                          HeadlineLargeText(
                            text: "Staff CRM",
                            textColor: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),

                          const Gap(12),

                          // Subtitle with better contrast
                          LabelLargeText(
                            text: "Enter your PIN to continue",
                            textColor: colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),

                          const Gap(48),

                          CustomTextformField(
                            controller: _pinController,
                            autofocus: true,
                            isObsecure: true,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (p0) async {
                              if (_fomrKey.currentState!.validate()) {
                                final isSuccess = await viewmodel.login(
                                  pin: _pinController.text,
                                );
                                if (isSuccess && context.mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const HomeView(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              }
                            },
                            validator: (value) {
                              if (value == null && value!.isNotEmpty) {
                                return "Enter Pin Number";
                              }
                              if (value.length < 4) {
                                return "Pin length should be more than 4";
                              }
                              return null;
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            labelText: "• • • • • •",
                          ),

                          const Gap(32),

                          Consumer(
                            builder: (context, ref, child) {
                              final status = ref.watch(
                                loginViewmodelProvider.select(
                                  (value) => value.loginStatus,
                                ),
                              );
                              final isLoading = status == Status.loading;
                              return CustomButton(
                                isLoading: isLoading,
                                loadingText: "Loginin...",
                                width: double.infinity,
                                onPressed: () async {
                                  if (_fomrKey.currentState!.validate()) {
                                    final isSuccess = await viewmodel.login(
                                      pin: _pinController.text,
                                    );
                                    if (isSuccess && context.mounted) {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const HomeView(),
                                        ),
                                        (route) => false,
                                      );
                                    }
                                  }
                                },
                                btnText: "Login",
                              );
                            },
                          ),
                          const Spacer(flex: 1),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shield_rounded,
                                size: 16,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              const Gap(8),
                              LabelLargeText(
                                text: "Secure Access Only",
                                textColor: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ],
                          ),
                          const Gap(20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
