import 'package:auth/src/data/models/user_model.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/enums/user_type.dart';
import 'package:hive_ce/hive.dart';

class UserAdapter extends TypeAdapter<UserEntity> {
  @override
  final typeId = 0;

  @override
  UserEntity read(BinaryReader reader) {
    final data = reader.readList();

    var type = UserType.individualProvider;
    if (data.length > 5 && data[5] is String) {
      try {
        type = UserType.fromString(data[5] as String);
      } on Object catch (_) {}
    }

    return UserModel(
      id: data[0] as String,
      email: data[1] as String,
      isVerified: data[2] as bool,
      isActive: data[3] as bool,
      type: type,
    );
  }

  @override
  void write(BinaryWriter writer, UserEntity obj) {
    writer.writeList([
      obj.id,
      obj.email,
      obj.isVerified,
      obj.isActive,
      obj.type?.value,
    ]);
  }
}
