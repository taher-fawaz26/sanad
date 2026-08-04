/// Reusable bottom-sheet navigation infrastructure.
///
/// Provides `ModalSheetRoute`, a real `PopupRoute` pushed on the root
/// navigator so nested sheets behave like LinkedIn: the previous sheet
/// expands to fullscreen as a new one is pushed, and un-morphs on pop.
/// Features never construct routes directly — use `SheetNavigator` /
/// `showSheet`.
library;

export 'src/gesture/sheet_drag_controller.dart';
export 'src/presentation/sheet_navigator.dart';
export 'src/presentation/widgets/sheet_scaffold.dart';
export 'src/presentation/widgets/sheet_snap.dart';
export 'src/route/modal_sheet_route.dart';
export 'src/route/sheet_route_settings.dart';
export 'src/route/sheet_size.dart';
export 'src/route/sheet_transitions.dart';
