import 'package:document_flow/document_flow.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:registration/src/domain/provider_type/provider_type_spec.dart';

/// Cross-step registration data that isn't part of the document-flow
/// pipeline (onboarding token, chosen provider type, entered names).
///
/// Document upload/extract/submit state lives entirely in the shared
/// [DocumentFlowBloc]; this cubit only carries what registration needs to
/// seed that bloc's [DocumentFlowContext] and to drive its own step routing.
class RegistrationDetails extends Equatable {
  const RegistrationDetails({
    this.email = '',
    this.onboardingToken,
    this.providerType,
    this.businessName = '',
    this.representativeName = '',
    this.fullName = '',
  });

  final String email;
  final String? onboardingToken;
  final ProviderTypeSpec? providerType;
  final String businessName;
  final String representativeName;
  final String fullName;

  bool get isOrganization => providerType?.requiresTradeLicence ?? false;

  DocumentFlowContext toContext() => DocumentFlowContext({
    'onboardingToken': onboardingToken,
    'providerType': providerType,
    'email': email,
    'businessName': businessName,
    'representativeName': representativeName,
    'fullName': fullName,
  });

  RegistrationDetails copyWith({
    String? email,
    String? onboardingToken,
    ProviderTypeSpec? providerType,
    String? businessName,
    String? representativeName,
    String? fullName,
  }) => RegistrationDetails(
    email: email ?? this.email,
    onboardingToken: onboardingToken ?? this.onboardingToken,
    providerType: providerType ?? this.providerType,
    businessName: businessName ?? this.businessName,
    representativeName: representativeName ?? this.representativeName,
    fullName: fullName ?? this.fullName,
  );

  @override
  List<Object?> get props => [
    email,
    onboardingToken,
    providerType,
    businessName,
    representativeName,
    fullName,
  ];
}

class RegistrationDetailsCubit extends Cubit<RegistrationDetails> {
  RegistrationDetailsCubit() : super(const RegistrationDetails());

  void setOnboarding({
    required String email,
    required String onboardingToken,
  }) => emit(state.copyWith(email: email, onboardingToken: onboardingToken));

  void setProviderType(ProviderTypeSpec type) =>
      emit(state.copyWith(providerType: type));

  void setOrganizationDetails({
    required String businessName,
    required String representativeName,
  }) => emit(
    state.copyWith(
      businessName: businessName,
      representativeName: representativeName,
    ),
  );

  void setFullName(String fullName) => emit(state.copyWith(fullName: fullName));
}
