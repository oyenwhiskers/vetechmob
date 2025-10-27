import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ProfileProvider>().fetch());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (provider.error != null) return Center(child: Text('Error: ${provider.error}'));

    final user = provider.user;
    final customer = provider.customer;
    if (user == null || customer == null) {
      return Center(
        child: ElevatedButton(
          onPressed: () async {
            await context.read<AuthProvider>().logout();
            if (!mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          },
          child: const Text('Session expired. Login again'),
        ),
      );
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user.name),
              subtitle: Text(user.email),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Contact'),
              subtitle: Text('Phone: ${customer.phone ?? '-'}\nAddress: ${customer.address ?? '-'}'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit profile'),
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _EditProfileScreen()));
                    if (!mounted) return;
                    context.read<ProfileProvider>().fetch();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.lock),
                  label: const Text('Change password'),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _ChangePasswordScreen())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: const Text('Delete account', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              final controller = TextEditingController();
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Confirm account deletion'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Enter your password to confirm.'),
                      const SizedBox(height: 8),
                      TextField(controller: controller, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirmed == true) {
                final err = await context.read<ProfileProvider>().deleteAccount(controller.text);
                if (err == null) {
                  if (!mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen();

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>();
    _name = TextEditingController(text: p.user?.name ?? '');
    _email = TextEditingController(text: p.user?.email ?? '');
    _phone = TextEditingController(text: p.customer?.phone ?? '');
    _address = TextEditingController(text: p.customer?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final err = await context.read<ProfileProvider>().update(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          address: _address.text.trim(),
        );
    setState(() => _saving = false);
    if (err == null && mounted) {
      Navigator.of(context).pop();
    } else if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator() : const Text('Save')),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordScreen extends StatefulWidget {
  const _ChangePasswordScreen();

  @override
  State<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final err = await context.read<ProfileProvider>().changePassword(_current.text, _next.text);
    setState(() => _saving = false);
    if (err == null && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
    } else if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _current, decoration: const InputDecoration(labelText: 'Current password'), obscureText: true, validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _next, decoration: const InputDecoration(labelText: 'New password'), obscureText: true, validator: (v) => v == null || v.length < 8 ? 'Min 8 chars' : null),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator() : const Text('Update'))),
            ],
          ),
        ),
      ),
    );
  }
}
