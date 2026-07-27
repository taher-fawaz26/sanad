abstract final class WorkerApiPaths {
  static const String workers = 'workers';
  static const String invitations = 'workers/invitations';
  static String worker(String id) => 'workers/$id';
  static String workerStatus(String id) => 'workers/$id/status';
  static String resendInvitation(String id) => 'workers/invitations/$id/resend';
  static String cancelInvitation(String id) => 'workers/invitations/$id/cancel';
  static String deleteInvitation(String id) => 'workers/invitations/$id';
}
