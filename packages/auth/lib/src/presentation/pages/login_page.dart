import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onAuthenticated});

  final VoidCallback? onAuthenticated;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
      AuthLoginEvent(
        _identifierController.text.trim(),
        _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoginSuccessState) {
          widget.onAuthenticated?.call();
        } else if (state is AuthLoginFailureState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSection(
                    title: 'auth.login_title'.tr(),
                    caption: 'auth.login_caption'.tr(),
                  ),
                  AppSegmentedControl(
                    segments: ['auth.phone', 'auth.email'],
                    selectedIndex: 0,
                    onChanged: (index) {
                      _identifierController.text = '';
                      _passwordController.text = '';
                    },
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    controller: _identifierController,
                    label: 'auth.phone_or_email'.tr(),
                    hint: 'auth.phone_or_email_hint'.tr(),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value?.trim().isEmpty ?? true
                        ? 'auth.field_required'.tr()
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordController,
                    label: 'auth.password'.tr(),
                    hint: 'auth.password_hint'.tr(),
                    obscureText: true,
                    validator: (value) => value?.trim().isEmpty ?? true
                        ? 'auth.field_required'.tr()
                        : null,
                  ),
                  const SizedBox(height: 32),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoginLoadingState;
                      return AppButton(
                        onPressed: isLoading ? null : () => _submit(context),
                        label: 'auth.login'.tr(),
                        isLoading: isLoading,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
