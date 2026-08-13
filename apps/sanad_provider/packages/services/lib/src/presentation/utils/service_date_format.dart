const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Formats [date] as `"Jan 10, 2025"` — shared by the request details page
/// and the request list item so both stay in sync.
String formatShortDate(DateTime date) =>
    '${_monthNames[date.month - 1].substring(0, 3)} ${date.day}, ${date.year}';
