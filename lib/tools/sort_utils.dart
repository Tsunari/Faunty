import '../models/user_entity.dart';

/// Sortable fields for users.
enum UserSortField { firstName, lastName, email }

/// Ascending or descending.
enum SortOrder { asc, desc }

/// Option to control user sorting.
class UserSortOption {
  final UserSortField field;
  final SortOrder order;

  const UserSortOption({this.field = UserSortField.firstName, this.order = SortOrder.asc});
}

/// Returns a comparator for the given [option].
/// If [option] is null, callers should skip sorting.
int compareUsersByOption(UserEntity a, UserEntity b, UserSortOption option) {
  String va(UserEntity u) {
    switch (option.field) {
      case UserSortField.firstName:
        return u.firstName.toLowerCase();
      case UserSortField.lastName:
        return u.lastName.toLowerCase();
      case UserSortField.email:
        return u.email.toLowerCase();
    }
  }

  final left = va(a);
  final right = va(b);
  final cmp = left.compareTo(right);
  if (cmp != 0) return option.order == SortOrder.asc ? cmp : -cmp;

  // tie-breakers: firstName, lastName, email (stable deterministic order)
  final t1 = a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
  if (t1 != 0) return option.order == SortOrder.asc ? t1 : -t1;
  final t2 = a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
  if (t2 != 0) return option.order == SortOrder.asc ? t2 : -t2;
  final t3 = a.email.toLowerCase().compareTo(b.email.toLowerCase());
  return option.order == SortOrder.asc ? t3 : -t3;
}

