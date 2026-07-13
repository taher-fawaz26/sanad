import 'package:equatable/equatable.dart';

/// Standard contract for converting a Data-layer Model to a Domain Entity.
// Base class pattern: single abstract method is intentional by design.
// ignore: one_member_abstracts
abstract class EntityConverter<T extends Equatable> {
  T toEntity();
}
