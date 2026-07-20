abstract final class WorkerApiPaths {
  static const String workers = 'workers';
  static const String invitations = 'workers/invitations';
  static String resendInvitation(String id) => 'workers/invitations/$id/resend';
  static String cancelInvitation(String id) => 'workers/invitations/$id';
  static String worker(String id) => 'workers/$id';
}
