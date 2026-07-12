import 'package:auth/auth.dart';
import 'package:branches/branches.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProviderSettingsPage extends StatelessWidget {
  const ProviderSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLogoutSuccessState) {
          context.go(AuthRoutes.login);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('settings.title'.tr())),
        body: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.store_outlined),
              title: Text('settings.branches'.tr()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(BranchRoutes.list),
            ),
            const Divider(height: 1),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: AppButton(
                label: 'settings.logout'.tr(),
                onPressed: () =>
                    context.read<AuthBloc>().add(AuthLogoutEvent()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
