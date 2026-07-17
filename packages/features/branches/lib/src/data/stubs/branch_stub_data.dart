import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/entities/branch_time_slot_entity.dart';

/// Static company schedule used until the real API endpoint is wired.
const kStaticCompanySchedule = <BranchAvailabilityEntity>[
  BranchAvailabilityEntity(
    day: 'SATURDAY',
    slots: [BranchTimeSlotEntity(from: '09:00', to: '18:00')],
  ),
  BranchAvailabilityEntity(
    day: 'SUNDAY',
    slots: [BranchTimeSlotEntity(from: '10:00', to: '16:00')],
  ),
  BranchAvailabilityEntity(
    day: 'MONDAY',
    slots: [BranchTimeSlotEntity(from: '08:00', to: '17:00')],
  ),
];

/// Static branch managers used until the workers API is wired.
const kStaticBranchManagers = <BranchManagerEntity>[
  BranchManagerEntity(
    id: 'f490f1ee-6c54-4b01-90e6-d701748f0851',
    fullName: 'Ahmed Hassan',
    initials: 'AH',
  ),
  BranchManagerEntity(
    id: 'a12b3c4d-5e6f-7890-abcd-ef1234567890',
    fullName: 'Sara Al Mansouri',
    initials: 'SM',
  ),
  BranchManagerEntity(
    id: 'b23c4d5e-6f70-8901-bcde-f12345678901',
    fullName: 'Omar Khalid',
    initials: 'OK',
  ),
];
