/// Our own share-outcome model — `share_plus` types are never exposed.
enum ShareStatus {
  /// The content was shared to a target successfully.
  success,

  /// The share sheet was dismissed without choosing a target.
  dismissed,

  /// Sharing is unavailable on this platform / for this content.
  unavailable,
}
