import 'package:flutter/material.dart';
import '../../config/supabase_config.dart';
import 'chat_screen.dart';
import 'pdf_search_screen.dart';
import 'news_screen.dart';
import 'app_builder_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;

  final _screens = const [
    ChatScreen(),
    PdfSearchScreen(),
    NewsScreen(),
    AppBuilderScreen(),
    ReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = SupabaseConfig.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Super Agent'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(child: Text((user?.email ?? 'U')[0].toUpperCase())),
          ),
          IconButton(
            onPressed: () async {
              await SupabaseConfig.client.auth.signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: _screens[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat), label: 'Agent'),
          NavigationDestination(icon: Icon(Icons.picture_as_pdf), label: 'PDFs'),
          NavigationDestination(icon: Icon(Icons.newspaper), label: 'News'),
          NavigationDestination(icon: Icon(Icons.build), label: 'Apps'),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Reports'),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.userMetadata?['name'] ?? 'User'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: const CircleAvatar(child: Icon(Icons.person, size: 40)),
              decoration: const BoxDecoration(color: Colors.deepPurple),
            ),
            ListTile(leading: const Icon(Icons.person), title: Text('Username: ${user?.userMetadata?['username'] ?? ''}')),
            ListTile(leading: const Icon(Icons.storage), title: const Text('Supabase: Secure Storage'), subtitle: const Text('RLS protected')),
            const Divider(),
            const Padding(padding: EdgeInsets.all(16), child: Text('AI Skills Installed:\n• PDF Search\n• Top 5 News\n• App Builder\n• Report Series\n• Web Search\n• Fetch URL\n• File Mgmt\n• Image Gen\n• All work you tell it')),
          ],
        ),
      ),
    );
  }
}
