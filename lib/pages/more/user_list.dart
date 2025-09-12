import 'package:faunty/components/custom_snackbar.dart';
import 'package:faunty/components/role_gate.dart';
import 'package:faunty/components/custom_chip.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'package:flutter/material.dart';
import '../../models/user_entity.dart';
import '../../models/user_roles.dart';
import 'users_page.dart';

class UserListWithScrollbar extends StatefulWidget {
  final List<UserEntity> users;
  final ColorScheme colorScheme;
  final UserEntity currentUser;
  const UserListWithScrollbar({super.key, required this.users, required this.colorScheme, required this.currentUser});

  @override
  State<UserListWithScrollbar> createState() => UserListWithScrollbarState();
}

class UserListWithScrollbarState extends State<UserListWithScrollbar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.superuser:
        return Icons.admin_panel_settings_outlined;
      case UserRole.hoca:
        return Icons.school_outlined;
      case UserRole.baskan:
      case UserRole.talebe:
        return Icons.person_outline;
      case UserRole.user:
        return Icons.person_add_alt_1_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.separated(
        controller: _scrollController,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.users.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: widget.colorScheme.outline.withOpacity(0.2)),
        itemBuilder: (context, idx) {
          final u = widget.users[idx];
          return ListTile(
            leading: Stack(
              children: [
                GestureDetector(
                  onTap: u.isPlaceholder
                      ? () {
                          showCustomSnackBar(context, translation('This is a placeholder user. They can register using this email.'));
                        }
                      : null,
                  child: Icon(_getRoleIcon(u.role), color: widget.colorScheme.primary),
                ),
                if (u.isPlaceholder)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        showCustomSnackBar(context, translation('This is a placeholder user. They can register using this email.'));
                      },
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text('${u.firstName} ${u.lastName}', style: TextStyle(color: widget.colorScheme.onSurface)),
            subtitle: (widget.currentUser.role == UserRole.superuser || 
                      (widget.currentUser.role == UserRole.hoca && u.isPlaceholder))
                ? Text(u.email, style: TextStyle(color: widget.colorScheme.onSurface.withOpacity(0.7)))
                : null,
            trailing: (u.uid == widget.currentUser.uid)
                ? null
                : SizedBox(
                    width: 90,
                    child: RoleGate(
                      minRole: UserRole.hoca,
                      child: RoleDropdown(
                        key: ValueKey('dropdown_${u.uid}'),
                        user: u,
                        colorScheme: widget.colorScheme,
                        enabled: widget.currentUser.role.index >= UserRole.hoca.index || widget.currentUser.role == UserRole.superuser,
                      ),
                    ),
                  ),
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
          );
        },
      ),
    );
  }
}
