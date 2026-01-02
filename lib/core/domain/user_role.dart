enum UserRole {
  parent,
  student,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.parent:
        return 'Parent';
      case UserRole.student:
        return 'Student';
    }
  }

  String get icon {
    switch (this) {
      case UserRole.parent:
        return '👨‍👩‍👧‍👦';
      case UserRole.student:
        return '🎓';
    }
  }
}
