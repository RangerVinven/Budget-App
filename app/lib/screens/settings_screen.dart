import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../models/category_group.dart';
import '../models/category_item.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _editProfile(BuildContext context, WidgetRef ref) {
    final user = ref.read(userProfileProvider);
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(userProfileProvider.notifier).updateProfile(
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addDefaultGroup(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category Group'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Group Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(defaultCategoriesProvider.notifier).addGroup(
                  CategoryGroup(id: DateTime.now().millisecondsSinceEpoch.toString(), name: ctrl.text.trim()),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addDefaultItem(BuildContext context, WidgetRef ref, String groupId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Item Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(defaultCategoriesProvider.notifier).addItemToGroup(
                  groupId,
                  CategoryItem(id: DateTime.now().millisecondsSinceEpoch.toString(), name: ctrl.text.trim()),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editDefaultGroup(BuildContext context, WidgetRef ref, CategoryGroup group) {
    final ctrl = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category Group'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Group Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(defaultCategoriesProvider.notifier).updateGroupName(group.id, ctrl.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editDefaultItem(BuildContext context, WidgetRef ref, String groupId, CategoryItem item) {
    final ctrl = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Item Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(defaultCategoriesProvider.notifier).updateItemName(groupId, item.id, ctrl.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final defaultCategories = ref.watch(defaultCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Revert to default categories',
            onPressed: () {
              ref.read(defaultCategoriesProvider.notifier).revertToDefault();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reverted to default categories')));
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: const Icon(Icons.edit),
            onTap: () => _editProfile(context, ref),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Default Budget Template', style: Theme.of(context).textTheme.titleLarge),
          ),
          ...defaultCategories.map((group) {
            return ExpansionTile(
              title: GestureDetector(
                onTap: () => _editDefaultGroup(context, ref, group),
                child: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => ref.read(defaultCategoriesProvider.notifier).deleteGroup(group.id),
              ),
              children: [
                ...group.items.map((item) => ListTile(
                  title: Text(item.name),
                  onTap: () => _editDefaultItem(context, ref, group.id, item),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => ref.read(defaultCategoriesProvider.notifier).deleteItem(group.id, item.id),
                  ),
                )),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Add Item'),
                  onTap: () => _addDefaultItem(context, ref, group.id),
                ),
              ],
            );
          }),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              onPressed: () => _addDefaultGroup(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Category Group'),
            ),
          ),
        ],
      ),
    );
  }
}