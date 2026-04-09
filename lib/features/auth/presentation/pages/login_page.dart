import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:freshveggie/core/widgets/image.dart';

import '../cubits/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const pageBackground = Color(0xFFFFFFFF);
    const darkGreen = Color(0xFF2E7D32);
    const textGreen = Color(0xFF388E3C);
    const softGreen = Color(0xFFEAF8E7);
    const mutedText = Color(0xFF6B7280);

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.message)),
            );
        }

        if (state is Authenticated) {
          context.go('/home');
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: pageBackground,
          body: SafeArea(
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding =
                        constraints.maxWidth >= 700 ? 32.0 : 22.0;
                    final contentWidth = constraints.maxWidth >= 700
                        ? 420.0
                        : (constraints.maxWidth - (horizontalPadding * 2))
                            .clamp(320.0, 420.0)
                            .toDouble();

                    return Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentWidth),
                          child: Container(
                            color: pageBackground,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _BannerCard(
                                      backgroundColor: const Color(0xFFF4FBF1),
                                      shadowColor: const Color(0x1C2E7D32),
                                    ),
                                    const SizedBox(height: 28),
                                    Text(
                                      'VeggieFresh Market',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: textGreen,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Welcome back! Sign in to continue.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: mutedText,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    _InputField(
                                      controller: _emailController,
                                      hintText: 'Email Address',
                                      prefixIcon: Icons.mail_outline_rounded,
                                      backgroundColor: softGreen,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: _validateEmail,
                                    ),
                                    const SizedBox(height: 14),
                                    _InputField(
                                      controller: _passwordController,
                                      hintText: 'Password',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      backgroundColor: softGreen,
                                      obscureText: _obscurePassword,
                                      validator: _validatePassword,
                                      suffix: IconButton(
                                        splashRadius: 18,
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: const Color(0xFF7A8B76),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 58,
                                      child: ElevatedButton(
                                        onPressed: isLoading
                                            ? null
                                            : _submitEmailSignIn,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: darkGreen,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(22),
                                          ),
                                          textStyle: GoogleFonts.poppins(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        child: const Text('Sign In'),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextButton(
                                      onPressed: isLoading ? null : () {},
                                      style: TextButton.styleFrom(
                                        foregroundColor: textGreen,
                                        padding: EdgeInsets.zero,
                                        textStyle: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      child: const Text('Forgot Password?'),
                                    ),
                                    const SizedBox(height: 18),
                                    Row(
                                      children: [
                                        const Expanded(
                                            child: Divider(
                                                color: Color(0xFFE3E7E1))),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Text(
                                            'Or sign in with',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: mutedText,
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                            child: Divider(
                                                color: Color(0xFFE3E7E1))),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    Center(
                                      child: _GoogleButton(
                                        isLoading: isLoading,
                                        onTap: () => context
                                            .read<AuthCubit>()
                                            .signInWithGoogle(),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Center(
                                      child: Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            'New here? ',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: mutedText,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: isLoading ? null : () {},
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              foregroundColor: textGreen,
                                              textStyle: GoogleFonts.dmSans(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            child:
                                                const Text('Create an Account'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (isLoading)
                  Container(
                    color: const Color(0x66000000),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitEmailSignIn() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    context.read<AuthCubit>().signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  String? _validateEmail(String? value) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return 'Email is required.';
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(trimmedValue)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Password is required.';
    }

    return null;
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.backgroundColor,
    required this.shadowColor,
  });

  final Color backgroundColor;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -10,
            left: -40,
            right: -40,
            child: Container(
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFCBF1B8),
                    Color(0xFFEFFAE8),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -24,
            top: 18,
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE0F4D5),
              ),
            ),
          ),
          Positioned(
            left: -20,
            top: 60,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD8F0CB),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Image.asset(
              Images.logo,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.eco_rounded,
                    size: 88,
                    color: Color(0xFF4CAF50),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.backgroundColor,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final Color backgroundColor;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF243126),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF7A8B76),
        ),
        filled: true,
        fillColor: backgroundColor,
        prefixIcon: Icon(
          prefixIcon,
          color: const Color(0xFF5D7F4A),
        ),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color(0xFF7BBE68),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.onTap,
    required this.isLoading,
  });

  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isLoading ? null : onTap,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE2E8E0),
            ),
          ),
          child: Center(
            child: Text(
              'G',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [
                      Color(0xFF4285F4),
                      Color(0xFF34A853),
                      Color(0xFFFBBC05),
                      Color(0xFFEA4335),
                    ],
                  ).createShader(const Rect.fromLTWH(0, 0, 28, 28)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
