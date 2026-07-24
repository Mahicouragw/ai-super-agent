import 'package:flutter/material.dart';
import '../../services/device_accounts_service.dart';

/// Continue with AI Super Agent - Like Google account chooser
/// Shows accounts created on this device, saved in server, cloud, local
/// Branded as AI Super Agent, not Google, but works like Google account chooser
class ContinueWithAISuperAgent extends StatefulWidget {
  final Function(String email, String name) onAccountSelected;
  final Function() onAddNewAccount;

  const ContinueWithAISuperAgent({
    super.key,
    required this.onAccountSelected,
    required this.onAddNewAccount,
  });

  @override
  State<ContinueWithAISuperAgent> createState() => _ContinueWithAISuperAgentState();
}

class _ContinueWithAISuperAgentState extends State<ContinueWithAISuperAgent> {
  final _deviceAccountsService = DeviceAccountsService();
  List<Map<String, String>> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _loading = true);
    try {
      final accounts = await _deviceAccountsService.getAllDeviceAccounts();
      setState(() {
        _accounts = accounts;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(children: [CircularProgressIndicator(strokeWidth: 2), SizedBox(width: 12), Text('Loading your accounts...', style: TextStyle(fontSize: 12))]),
        ),
      );
    }

    if (_accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.deepPurple.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.smart_toy, size: 16, color: Colors.deepPurple),
                ),
                const SizedBox(width: 8),
                const Text('Continue with AI Super Agent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                  child: const Text('On this device', style: TextStyle(fontSize: 9, color: Colors.green)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Choose from accounts you created on this device. Saved in server, cloud storage, and local storage.', style: TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 12),
            ..._accounts.map((acc) => _accountTile(acc)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: widget.onAddNewAccount,
              icon: const Icon(Icons.person_add_outlined, size: 16),
              label: const Text('Add another account', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 36)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountTile(Map<String, String> acc) {
    final email = acc['email'] ?? '';
    final name = acc['name'] ?? email.split('@')[0];
    final initial = name.isNotEmpty ? name[0].toUpperCase() : email[0].toUpperCase();

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.deepPurple.shade100,
        child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
      ),
      title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(email, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: () => widget.onAccountSelected(email, name),
    );
  }
}
