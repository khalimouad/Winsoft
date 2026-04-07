import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_user.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/repositories/user_repository.dart';

class TeamPage extends ConsumerWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(userListProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Équipe',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    usersAsync.whenOrNull(
                            data: (list) => Text(
                                '${list.length} membre(s)',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme
                                        .onSurfaceVariant))) ??
                        const SizedBox.shrink(),
                  ],
                ),
                if (auth.isAdmin)
                  FilledButton.icon(
                    onPressed: () => _showAddDialog(context, ref),
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Inviter un membre'),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Role legend
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppUser.roles.map((role) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _RoleChip(role: role),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: usersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Erreur: $e')),
                data: (users) => LayoutBuilder(
                  builder: (ctx, constraints) {
                    final crossAxisCount =
                        constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
                    return GridView.builder(
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: users.length,
                      itemBuilder: (ctx, i) => _UserCard(
                        user: users[i],
                        currentUser: auth.user,
                        isAdmin: auth.isAdmin,
                        onEdit: () =>
                            _showEditDialog(context, ref, users[i]),
                        onToggle: () => ref
                            .read(userListProvider.notifier)
                            .toggleActive(users[i]),
                        onDelete: () =>
                            _confirmDelete(context, ref, users[i]),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    _showUserDialog(context, ref, null);
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, AppUser user) {
    _showUserDialog(context, ref, user);
  }

  void _showUserDialog(BuildContext context, WidgetRef ref, AppUser? user) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passCtrl = TextEditingController();
    String selectedRole = user?.role ?? 'employee';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(user == null ? 'Inviter un membre' : 'Modifier'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nom complet *'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Email *'),
                    validator: (v) =>
                        v == null || !v.contains('@')
                            ? 'Email invalide'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: user == null
                          ? 'Mot de passe *'
                          : 'Nouveau mot de passe (laisser vide)',
                    ),
                    validator: (v) => user == null && (v == null || v.length < 4)
                        ? 'Min. 4 caractères'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Rôle'),
                    items: AppUser.roles
                        .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(AppUser.roleLabel(r))))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => selectedRole = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final now = DateTime.now().millisecondsSinceEpoch;
                final hash = passCtrl.text.isNotEmpty
                    ? UserRepository.hashPassword(passCtrl.text)
                    : user?.passwordHash ?? '';
                final u = AppUser(
                  id: user?.id,
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  passwordHash: hash,
                  role: selectedRole,
                  isActive: user?.isActive ?? true,
                  createdAt: user?.createdAt ?? now,
                );
                if (user == null) {
                  await ref.read(userListProvider.notifier).add(u);
                } else {
                  await ref.read(userListProvider.notifier).edit(u);
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text(user == null ? 'Inviter' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le membre'),
        content: Text('Supprimer "${user.name}" de l\'équipe ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error),
            onPressed: () {
              ref.read(userListProvider.notifier).remove(user.id!);
              Navigator.of(ctx).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.currentUser,
    required this.isAdmin,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final AppUser user;
  final AppUser? currentUser;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = user.id == currentUser?.id;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _roleColor(user.role)
                      .withValues(alpha: 0.15),
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: _roleColor(user.role),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                if (!user.isActive)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2),
                      ),
                    ),
                  ),
                if (user.isActive)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMe)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Moi',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: theme
                                      .colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(user.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  _RoleChip(role: user.role, small: true),
                ],
              ),
            ),
            if (isAdmin && !isMe)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Modifier'),
                          dense: true,
                          contentPadding: EdgeInsets.zero)),
                  PopupMenuItem(
                      value: 'toggle',
                      child: ListTile(
                          leading: Icon(user.isActive
                              ? Icons.block
                              : Icons.check_circle_outline),
                          title: Text(
                              user.isActive ? 'Désactiver' : 'Activer'),
                          dense: true,
                          contentPadding: EdgeInsets.zero)),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                          leading: Icon(Icons.delete_outline,
                              color: Colors.red),
                          title: Text('Supprimer',
                              style: TextStyle(color: Colors.red)),
                          dense: true,
                          contentPadding: EdgeInsets.zero)),
                ],
                onSelected: (action) {
                  switch (action) {
                    case 'edit':   onEdit(); break;
                    case 'toggle': onToggle(); break;
                    case 'delete': onDelete(); break;
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':     return const Color(0xFF1565C0);
      case 'manager':   return const Color(0xFF6A1B9A);
      case 'comptable': return const Color(0xFF2E7D32);
      default:          return const Color(0xFFE65100);
    }
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role, this.small = false});
  final String role;
  final bool small;

  static const _colors = {
    'admin':     Color(0xFF1565C0),
    'manager':   Color(0xFF6A1B9A),
    'comptable': Color(0xFF2E7D32),
    'employee':  Color(0xFFE65100),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[role] ?? Colors.grey;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 10, vertical: small ? 3 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        AppUser.roleLabel(role),
        style: TextStyle(
          color: color,
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
