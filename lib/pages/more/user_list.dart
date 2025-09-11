import 'package:faunty/components/role_gate.dart';
import 'package:faunty/components/custom_chip.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.separated(
        controller: _scrollController,
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: widget.users.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: widget.colorScheme.outline.withOpacity(0.2)),
        itemBuilder: (context, idx) {
          final u = widget.users[idx];
          return ListTile(
            leading: Icon(Icons.person_outline, color: widget.colorScheme.primary),
            title: Row(
              children: [
                Text('${u.firstName} ${u.lastName}', style: TextStyle(color: widget.colorScheme.onSurface)),
                if (u.isPlaceholder) ...[
                  const SizedBox(width: 8),
                  RoleGate(
                    minRole: UserRole.hoca,
                    child: CustomContainerChip(
                      label: 'Placeholder',
                      backgroundColor: widget.colorScheme.secondary.withOpacity(0.1),
                      textColor: widget.colorScheme.secondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
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
