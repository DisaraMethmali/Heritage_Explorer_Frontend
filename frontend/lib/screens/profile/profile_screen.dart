import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/gradient_button.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showChangePassword = false;
  bool _showVoiceSettings = false;
  final _oldPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isChangingPwd = false;

  @override
  void dispose() {
    _oldPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        final user = auth.user;
        if (user == null) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundDark,
            appBar: AppBar(title: const Text('Profile')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Not logged in',
                      style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: 'Sign In',
                    icon: Icons.login,
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final charInfo = AppConstants.characters[
            user.expertiseLevel == 'researcher'
                ? 'citizen'
                : (user.expertiseLevel == 'child' ? 'nilame' : 'king')];

        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sign out',
                onPressed: _confirmLogout,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // User header
                _buildProfileHeader(user),
                const SizedBox(height: 20),

                // Expertise level
                _buildExpertiseSection(auth, user),
                const SizedBox(height: 16),

                // Voice settings
                _buildVoiceSettings(),
                const SizedBox(height: 16),

                // Change password
                _buildChangePassword(auth),
                const SizedBox(height: 16),

                // Account info
                _buildAccountInfo(user),
                const SizedBox(height: 24),

                // Sign out
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Sign Out',
                        style: TextStyle(color: Colors.red)),
                    onPressed: _confirmLogout,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(user) {
    final expertiseEmoji =
        AppConstants.expertiseIcons[user.expertiseLevel] ?? '📖';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.deepMaroon.withOpacity(0.8),
            AppTheme.primaryGold.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGold.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGold.withOpacity(0.2),
              border: Border.all(color: AppTheme.primaryGold, width: 2),
            ),
            child: Center(
              child: Text(
                user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : user.username[0].toUpperCase(),
                style: const TextStyle(
                    color: AppTheme.primaryGold,
                    fontSize: 30,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty ? user.fullName : user.username,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  '@${user.username}',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primaryGold.withOpacity(0.5)),
                      ),
                      child: Text(
                        '$expertiseEmoji ${user.expertiseLevel.toUpperCase()}',
                        style: const TextStyle(
                            color: AppTheme.primaryGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.jade.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.jade.withOpacity(0.4)),
                      ),
                      child: Text(
                        '${user.totalSessions} sessions',
                        style: const TextStyle(
                            color: AppTheme.jade, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertiseSection(AuthProvider auth, user) {
    return _settingsCard(
      title: 'Expertise Level',
      subtitle: 'Customize how answers are explained to you',
      icon: Icons.school_outlined,
      child: Column(
        children: AppConstants.expertiseLevels.map((level) {
          final emoji = AppConstants.expertiseIcons[level] ?? '📖';
          final desc = AppConstants.expertiseDescriptions[level] ?? '';
          final selected = user.expertiseLevel == level;
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InkWell(
              onTap: () async {
                final err = await auth.updateExpertiseLevel(level);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err ?? '✅ Updated to $level'),
                      backgroundColor:
                          err != null ? Colors.red : Colors.green,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryGold.withOpacity(0.15)
                      : AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? AppTheme.primaryGold
                        : AppTheme.borderColor,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level.toUpperCase(),
                            style: TextStyle(
                              color: selected
                                  ? AppTheme.primaryGold
                                  : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(desc,
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle,
                          color: AppTheme.primaryGold, size: 20),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVoiceSettings() {
    return _settingsCard(
      title: 'Voice Settings',
      subtitle: 'Text-to-speech configuration',
      icon: Icons.record_voice_over,
      child: _showVoiceSettings
          ? Column(
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Voice settings are applied in the chat. Long-press any bot message to hear it read aloud.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    children: [
                      _voiceTip('🎙️ Tap the mic button to speak your question'),
                      _voiceTip('🔊 Tap the speaker icon on any message to hear it'),
                      _voiceTip('⏹️ Tap again to stop speech'),
                    ],
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
      trailing: IconButton(
        icon: Icon(
          _showVoiceSettings ? Icons.expand_less : Icons.expand_more,
          color: Colors.white54,
        ),
        onPressed: () =>
            setState(() => _showVoiceSettings = !_showVoiceSettings),
      ),
    );
  }

  Widget _voiceTip(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            const SizedBox(width: 4),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
            ),
          ],
        ),
      );

  Widget _buildChangePassword(AuthProvider auth) {
    return _settingsCard(
      title: 'Change Password',
      subtitle: 'Update your account password',
      icon: Icons.lock_outline,
      trailing: IconButton(
        icon: Icon(
          _showChangePassword ? Icons.expand_less : Icons.expand_more,
          color: Colors.white54,
        ),
        onPressed: () =>
            setState(() => _showChangePassword = !_showChangePassword),
      ),
      child: _showChangePassword
          ? Column(
              children: [
                const SizedBox(height: 12),
                _pwdField(_oldPwdCtrl, 'Current Password', _obscureOld,
                    () => setState(() => _obscureOld = !_obscureOld)),
                const SizedBox(height: 10),
                _pwdField(_newPwdCtrl, 'New Password', _obscureNew,
                    () => setState(() => _obscureNew = !_obscureNew)),
                const SizedBox(height: 10),
                _pwdField(
                    _confirmPwdCtrl,
                    'Confirm New Password',
                    _obscureConfirm,
                    () => setState(
                        () => _obscureConfirm = !_obscureConfirm)),
                const SizedBox(height: 14),
                GradientButton(
                  label: 'Change Password',
                  icon: Icons.lock,
                  isLoading: _isChangingPwd,
                  onPressed: () => _changePassword(auth),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _pwdField(TextEditingController ctrl, String label, bool obscure,
      VoidCallback toggle) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: toggle,
        ),
      ),
    );
  }

  Widget _buildAccountInfo(user) {
    return _settingsCard(
      title: 'Account Information',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _infoRow('Email', user.email),
          _infoRow('Username', '@${user.username}'),
          _infoRow('Age Group', user.ageGroup),
          if (user.lastLogin != null)
            _infoRow('Last Login', user.lastLogin!.split('T').first),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Text('$label:',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );

  Widget _settingsCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryGold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                    if (subtitle != null)
                      Text(subtitle,
                          style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12)),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          child,
        ],
      ),
    );
  }

  Future<void> _changePassword(AuthProvider auth) async {
    if (_newPwdCtrl.text != _confirmPwdCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    if (_newPwdCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    setState(() => _isChangingPwd = true);
    final err = await auth.changePassword(
      _oldPwdCtrl.text,
      _newPwdCtrl.text,
    );
    setState(() => _isChangingPwd = false);
    if (mounted) {
      if (err == null) {
        _oldPwdCtrl.clear();
        _newPwdCtrl.clear();
        _confirmPwdCtrl.clear();
        setState(() => _showChangePassword = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Password changed'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Sign Out',
            style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }
}
