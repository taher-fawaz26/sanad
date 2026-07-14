import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:services/src/domain/entities/service_entity.dart';

/// Bordered service row — Figma add-branch services list (`966:3746`).
///
/// Layout: `[Featured icon] [Name + Category]`
class ServiceListCard extends StatelessWidget {
  const ServiceListCard({
    required this.service,
    super.key,
    this.onTap,
  });

  final ServiceEntity service;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppListCard(
      title: service.name,
      caption: service.category,
      leading: AppAvatar(
        backgroundColor: context.appColors.gray200,
      ),
      onTap: onTap,
    );
  }
}
