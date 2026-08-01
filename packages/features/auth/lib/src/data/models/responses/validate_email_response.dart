final class ValidateEmailResponseModel {
  const ValidateEmailResponseModel({
    required this.emailAvailable,
  });

  factory ValidateEmailResponseModel.fromJson(Map<String, dynamic> json) =>
      ValidateEmailResponseModel(
        emailAvailable: json['emailAvailable'] as bool,
      );

  final bool emailAvailable;

  Map<String, dynamic> toJson() => {
    'emailAvailable': emailAvailable,
  };
}
