enum UserRole { user, storeManager, admin }

extension UserRoleX on UserRole {
  String get asString => switch (this) {
    UserRole.user => 'user',
    UserRole.storeManager => 'store_manager',
    UserRole.admin => 'admin',
  };

  static UserRole fromString(String? value) {
    switch (value) {
      case 'store_manager':
        return UserRole.storeManager;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }
}
