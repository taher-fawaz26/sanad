import 'package:auth/src/data/models/user_model.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/enums/user_type.dart';
import 'package:hive_ce/hive.dart';

/// Hive [TypeAdapter] for persisting [UserEntity] to local storage.
///
/// Migration note — adding `type` (index 5): older records have 5 elements
/// (indices 0–4). A missing element at index 5 is treated as
/// [UserType.provider]
/// so existing provider sessions continue to work without forcing a sign-out.
class UserAdapter extends TypeAdapter<UserEntity> {
  @override
  final typeId = 0;

  @override
  UserEntity read(BinaryReader reader) {
    final data = reader.readList();

    var type = UserType.provider;
    if (data.length > 5 && data[5] is String) {
      try {
        type = UserType.fromString(data[5] as String);
      } on Object catch (_) {
        type = UserType.provider;
      }
    }

    return UserModel(
      sub: data[0] as String,
      identifier: data[1] as String,
      identifierType: data[2] as String,
      isVerified: data[3] as bool,
      isProfileCompleted: data[4] as bool,
      type: type,
    );
  }

  @override
  void write(BinaryWriter writer, UserEntity obj) {
    writer.writeList([
      obj.sub,
      obj.identifier,
      obj.identifierType,
      obj.isVerified,
      obj.isProfileCompleted,
      obj.type.value,
    ]);
  }
}
