enum UserRole { 
  superuser,
  hoca, 
  baskan, 
  talebe, 
  user, // needs to be assigned by hoca or above
  spectator, // only view access
  archived, // no access, for record-keeping, separate pages
  unknown // new unknown user, for requesting a name change
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.superuser:
        return 'Superuser';
      case UserRole.hoca:
        return 'Hoca';
      case UserRole.baskan:
        return 'Baskan';
      case UserRole.talebe:
        return 'Talebe';
      case UserRole.user:
        return 'User';
      case UserRole.spectator:
        return 'Spectator';
      case UserRole.archived:
        return 'Archived';
      case UserRole.unknown:
        return 'Unknown';
    }
  }

  // Example role-specific function
  void doRoleSpecificAction() {
    switch (this) {
      case UserRole.superuser:
        print('Superuser action');
        break;
      case UserRole.hoca:
        print('Hoca action');
        break;
      case UserRole.baskan:
        print('Baskan action');
        break;
      case UserRole.talebe:
        print('Talebe action');
        break;
      case UserRole.user:
        print('User action');
        break;
      case UserRole.spectator:
        print('Spectator action');
        break;
      case UserRole.archived:
        print('Archived action');
        break;
      case UserRole.unknown:
        print('Unknown action');
        break;
    }
  }
}

UserRole userRoleFromString(String role) {
  switch (role) {
    case 'Superuser':
      return UserRole.superuser;
    case 'Hoca':
      return UserRole.hoca;
    case 'Baskan':
      return UserRole.baskan;
    case 'Talebe':
      return UserRole.talebe;
    case 'User':
      return UserRole.user;
    case 'Spectator':
      return UserRole.spectator;
    case 'Archived':
      return UserRole.archived;
    case 'Unknown':
      return UserRole.unknown;
    default:
      return UserRole.user;
  }
}
