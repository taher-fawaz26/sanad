import 'package:flutter/foundation.dart';

/// Where the chat's context layer is resting.
enum AiChatContextExtent {
  /// Not on screen at all. There is nothing to offer.
  ///
  /// Absent rather than merely closed: no strip, no handle, no sliver of
  /// surface behind the composer. A conversation with no context looks exactly
  /// like a conversation that never had one.
  collapsed,

  /// A strip proud of the composer's top edge, carrying the agent's summary
  /// and the invitation to swipe.
  peek,

  /// Open, with the contextual content readable.
  expanded
  ;

  /// Whether the layer is on screen in this extent.
  bool get isVisible => this != AiChatContextExtent.collapsed;
}

/// Lets the chat page ask the context layer to move.
///
/// A request channel and nothing more: the layer owns its own geometry, its own
/// animation and its own gesture, and **nothing about whether there is content
/// travels through here**. Availability comes from `ChatContextCubit`, so a
/// controller cannot conjure a surface that has nothing to show.
///
/// Chat-local on purpose. This is not a sheet framework and must not become
/// one: `packages/sheet_navigation` owns modal sheets that are routes, and this
/// owns one strip inside one page's layout. The two have different lifetimes,
/// different z-order rules and different reasons to exist, and the version of
/// this that lived in the shared package made both harder to read.
class AiChatContextController extends ChangeNotifier {
  AiChatContextExtent _requested = AiChatContextExtent.peek;

  /// The extent most recently asked for. The layer honours it when it can —
  /// there is no way to request [AiChatContextExtent.expanded] on a layer with
  /// nothing in it.
  AiChatContextExtent get requested => _requested;

  /// Asks the layer to open.
  void expand() => _request(AiChatContextExtent.expanded);

  /// Asks the layer to return to its strip.
  void collapse() => _request(AiChatContextExtent.peek);

  void _request(AiChatContextExtent extent) {
    if (_requested == extent) {
      // Re-requesting the extent it is already at is still a request: a drag
      // may have moved the layer since, and the caller means "go back there".
      notifyListeners();
      return;
    }
    _requested = extent;
    notifyListeners();
  }
}
