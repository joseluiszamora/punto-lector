enum UserRole { user, storeManager, admin, superAdmin }

extension UserRoleX on UserRole {
  String get asString => switch (this) {
    UserRole.user => 'user',
    UserRole.storeManager => 'store_manager',
    UserRole.admin => 'admin',
    UserRole.superAdmin => 'super_admin',
  };

  static UserRole fromString(String? value) {
    switch (value) {
      case 'store_manager':
        return UserRole.storeManager;
      case 'admin':
        return UserRole.admin;
      case 'super_admin':
        return UserRole.superAdmin;
      default:
        return UserRole.user;
    }
  }

  bool get isAdmin => this == UserRole.admin || this == UserRole.superAdmin;
  bool get isStoreManager => this == UserRole.storeManager;
  bool get isUser => this == UserRole.user;
}
