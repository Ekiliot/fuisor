import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'privacy_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool autoplayVideos = true;
  bool useCellularData = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(EvaIcons.arrowBack, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'General'),
          _SwitchTile(
            icon: EvaIcons.bellOutline,
            title: 'Notifications',
            subtitle: 'Receive activity and system notifications',
            value: notificationsEnabled,
            onChanged: (v) => setState(() => notificationsEnabled = v),
          ),
          _SwitchTile(
            icon: EvaIcons.playCircleOutline,
            title: 'Autoplay videos',
            subtitle: 'Automatically play videos in the feed',
            value: autoplayVideos,
            onChanged: (v) => setState(() => autoplayVideos = v),
          ),
          _SwitchTile(
            icon: EvaIcons.wifiOff,
            title: 'Use cellular data',
            subtitle: 'Allow media loading on mobile data',
            value: useCellularData,
            onChanged: (v) => setState(() => useCellularData = v),
          ),

          const _Divider(),
          const _SectionHeader(title: 'Privacy'),
          _NavTile(
            icon: EvaIcons.lockOutline,
            title: 'Blocked accounts',
            subtitle: 'Manage the users you have blocked',
            onTap: () {},
          ),
          _NavTile(
            icon: EvaIcons.shieldOutline,
            title: 'Privacy Settings',
            subtitle: 'Control who can see your content and interact with you',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrivacySettingsScreen(),
                ),
              );
            },
          ),

          const _Divider(),
          const _SectionHeader(title: 'About'),
          _NavTile(
            icon: EvaIcons.infoOutline,
            title: 'About Fuisor',
            subtitle: 'Version, licenses and legal',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.5,
      color: Color(0xFF262626),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F0F),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: const TextStyle(color: Color(0xFF8E8E8E), fontSize: 12),
              ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF0095F6),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F0F),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: const TextStyle(color: Color(0xFF8E8E8E), fontSize: 12),
              ),
        trailing: const Icon(EvaIcons.arrowRightOutline, color: Colors.white, size: 18),
      ),
    );
  }
}
