/// UI-facing filter over the branches list — maps to the backend's
/// `status` query param when non-`all`.
enum BranchFilter { all, active, maintenance }
