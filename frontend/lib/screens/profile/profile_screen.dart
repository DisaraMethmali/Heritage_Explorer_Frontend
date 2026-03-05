import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_button.dart';
import '../auth/login_screen.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showChangePassword = false;
  bool _showVoiceSettings  = false;
  final _oldPwdCtrl     = TextEditingController();
  final _newPwdCtrl     = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  bool _obscureOld     = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _isChangingPwd  = false;

  String? _downloadingReport;

  // ── Colour palette ─────────────────────────────────────────────────────────
  static const Color _pageBg       = Color(0xFFF5F7FF);
  static const Color _appBarBg     = Color(0xFF0D47A1);
  static const Color _accent       = Color(0xFF1565C0);
  static const Color _accentDark   = Color(0xFF0D47A1);
  static const Color _yellowLight  = Color(0xFFFFF9C4);
  static const Color _yellowMid    = Color(0xFFFFF176);
  static const Color _yellowDeep   = Color(0xFFF9A825);
  static const Color _cardBg       = Colors.white;
  static const Color _border       = Color(0xFFBBCEF5);
  static const Color _surfaceBlue  = Color(0xFFE3F2FD);
  static const Color _textPrimary  = Color(0xFF0D2150);
  static const Color _textSub      = Color(0xFF3D5A99);
  static const Color _textHint     = Color(0xFF8DA5CC);

  @override
  void dispose() {
    _oldPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  // ── Report helpers ─────────────────────────────────────────────────────────
  Future<void> _downloadReport(String location) async {
    if (_downloadingReport != null) return;
    setState(() => _downloadingReport = location);

    final auth = context.read<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      _showSnack('User not logged in', isSuccess: false);
      setState(() => _downloadingReport = null);
      return;
    }

    final url =
        '${AppConstants.baseUrl}/report/user?location=$location&token=${auth.token}';
    final filename = location == 'all'
        ? 'full_report_${user.username}.pdf'
        : '${location}_report_${user.username}.pdf';

    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 60));

      if (res.statusCode != 200) {
        final body = jsonDecode(res.body);
        _showSnack(body['error'] ?? 'Download failed', isSuccess: false);
        return;
      }

      if (kIsWeb) {
        final blob   = html.Blob([res.bodyBytes], 'application/pdf');
        final urlBlob = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: urlBlob)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(urlBlob);
        _showSnack('Download started', isSuccess: true);
        return;
      }

      final dir    = await getTemporaryDirectory();
      final file   = File('${dir.path}/$filename');
      await file.writeAsBytes(res.bodyBytes);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        _showSnack('PDF saved to ${file.path}', isSuccess: true);
      }
    } catch (e) {
      _showSnack('Error: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _downloadingReport = null);
    }
  }

  void _showSnack(String msg, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isSuccess ? Colors.green.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        final user = auth.user;
        if (user == null) {
          return Scaffold(
            backgroundColor: _pageBg,
            appBar: _buildAppBar('Profile'),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Not logged in',
                      style: TextStyle(color: _textHint)),
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

        return Scaffold(
          backgroundColor: _pageBg,
          appBar: _buildAppBar('My Profile', actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              tooltip: 'Sign out',
              onPressed: _confirmLogout,
            ),
          ]),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(user),
                const SizedBox(height: 20),
                _buildExpertiseSection(auth, user),
                const SizedBox(height: 16),
                _buildVoiceSettings(),
                const SizedBox(height: 16),
                _buildChangePassword(auth),
                const SizedBox(height: 16),
                _buildAccountInfo(user),
                const SizedBox(height: 16),
                _buildReportSection(),
                const SizedBox(height: 24),
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

  PreferredSizeWidget _buildAppBar(String title,
      {List<Widget>? actions}) =>
      AppBar(
        backgroundColor: _appBarBg,
        elevation: 0,
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: actions,
      );

  // ── Profile header ─────────────────────────────────────────────────────────
  Widget _buildProfileHeader(user) {
    final expertiseEmoji =
        AppConstants.expertiseIcons[user.expertiseLevel] ?? '📖';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accentDark, _accent.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _yellowDeep.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
              color: _accentDark.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _yellowDeep.withOpacity(0.2),
              border: Border.all(color: _yellowDeep, width: 2),
            ),
            child: Center(
              child: Text(
                user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : user.username[0].toUpperCase(),
                style: const TextStyle(
                    color: _yellowMid,
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
                Text('@${user.username}',
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _badge(
                      '$expertiseEmoji ${user.expertiseLevel.toUpperCase()}',
                      bg: _yellowDeep.withOpacity(0.2),
                      border: _yellowDeep.withOpacity(0.55),
                      textColor: _yellowMid,
                    ),
                    const SizedBox(width: 8),
                    _badge(
                      '${user.totalSessions} sessions',
                      bg: Colors.white.withOpacity(0.12),
                      border: Colors.white24,
                      textColor: Colors.white70,
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

  Widget _badge(String text,
      {required Color bg,
      required Color border,
      required Color textColor}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Text(text,
            style: TextStyle(
                color: textColor, fontSize: 11, fontWeight: FontWeight.w700)),
      );

  // ── Expertise section ──────────────────────────────────────────────────────
  Widget _buildExpertiseSection(AuthProvider auth, user) {
    return _settingsCard(
      title: 'Expertise Level',
      subtitle: 'Customize how answers are explained to you',
      icon: Icons.school_outlined,
      child: Column(
        children: AppConstants.expertiseLevels.map((level) {
          final emoji    = AppConstants.expertiseIcons[level] ?? '📖';
          final desc     = AppConstants.expertiseDescriptions[level] ?? '';
          final selected = user.expertiseLevel == level;
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InkWell(
              onTap: () async {
                final err = await auth.updateExpertiseLevel(level);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(err ?? '✅ Updated to $level'),
                    backgroundColor:
                        err != null ? Colors.red : Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(12),
                  ));
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? _accent.withOpacity(0.1)
                      : _surfaceBlue.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? _accent : _border,
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
                              color: selected ? _accent : _textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(desc,
                              style: const TextStyle(
                                  color: _textHint, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle,
                          color: _accent, size: 20),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Voice settings ─────────────────────────────────────────────────────────
  Widget _buildVoiceSettings() {
    return _settingsCard(
      title: 'Voice Settings',
      subtitle: 'Text-to-speech configuration',
      icon: Icons.record_voice_over,
      trailing: IconButton(
        icon: Icon(
          _showVoiceSettings ? Icons.expand_less : Icons.expand_more,
          color: _textHint,
        ),
        onPressed: () =>
            setState(() => _showVoiceSettings = !_showVoiceSettings),
      ),
      child: _showVoiceSettings
          ? Column(
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Voice settings are applied in the chat. Long-press any bot message to hear it read aloud.',
                  style: TextStyle(color: _textSub, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _yellowLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _yellowDeep.withOpacity(0.35)),
                  ),
                  child: Column(
                    children: [
                      _voiceTip('🎙️ Tap the mic button to speak your question'),
                      _voiceTip(
                          '🔊 Tap the speaker icon on any message to hear it'),
                      _voiceTip('⏹️ Tap again to stop speech'),
                    ],
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _voiceTip(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            const SizedBox(width: 4),
            Expanded(
              child: Text(text,
                  style:
                      const TextStyle(color: _textSub, fontSize: 12)),
            ),
          ],
        ),
      );

  // ── Change password ────────────────────────────────────────────────────────
  Widget _buildChangePassword(AuthProvider auth) {
    return _settingsCard(
      title: 'Change Password',
      subtitle: 'Update your account password',
      icon: Icons.lock_outline,
      trailing: IconButton(
        icon: Icon(
          _showChangePassword ? Icons.expand_less : Icons.expand_more,
          color: _textHint,
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

  Widget _pwdField(TextEditingController ctrl, String label,
      bool obscure, VoidCallback toggle) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: _textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textSub),
        filled: true,
        fillColor: _surfaceBlue.withOpacity(0.4),
        prefixIcon: const Icon(Icons.lock_outline, color: _accent),
        suffixIcon: IconButton(
          icon: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: _textHint),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accent, width: 2)),
      ),
    );
  }

  // ── Account info ───────────────────────────────────────────────────────────
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
                style: const TextStyle(color: _textHint, fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );

  // ── PDF Report section ─────────────────────────────────────────────────────
  Widget _buildReportSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _yellowDeep.withOpacity(0.45)),
        gradient: LinearGradient(
          colors: [_cardBg, _yellowLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: _yellowDeep.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _yellowDeep.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf,
                    color: _yellowDeep, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historical Journey Report',
                      style: TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                    Text(
                      'Download your personalised PDF report',
                      style: TextStyle(color: _textHint, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),


          const SizedBox(height: 10),
          _fullReportButton(),
        ],
      ),
    );
  }

  Widget _locationButton({
    required String emoji,
    required String label,
    required String location,
    required Color color,
  }) {
    final isLoading  = _downloadingReport == location;
    final isDisabled = _downloadingReport != null && !isLoading;

    return GestureDetector(
      onTap: isDisabled ? null : () => _downloadReport(location),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isDisabled
              ? color.withOpacity(0.04)
              : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? color.withOpacity(0.2)
                : color.withOpacity(0.55),
            width: 1.5,
          ),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Column(
          children: [
            isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: color),
                  )
                : Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDisabled ? _textHint : _textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLoading
                      ? Icons.hourglass_top_rounded
                      : Icons.file_download_outlined,
                  color: isDisabled ? _textHint : color,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  isLoading ? 'Generating…' : 'Download PDF',
                  style: TextStyle(
                    color: isDisabled ? _textHint : color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fullReportButton() {
    final isLoading  = _downloadingReport == 'all';
    final isDisabled = _downloadingReport != null && !isLoading;

    return GestureDetector(
      onTap: isDisabled ? null : () => _downloadReport('all'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isDisabled
              ? null
              : LinearGradient(
                  colors: [_accentDark, _accent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: isDisabled ? _surfaceBlue : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled ? _border : _accentDark,
          ),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                      color: _accentDark.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            else
              Icon(
                Icons.download_for_offline_outlined,
                color: isDisabled ? _textHint : Colors.white,
                size: 20,
              ),
            const SizedBox(width: 10),
            Text(
              isLoading
                  ? 'Generating Full Report…'
                  : 'Download Full Report  (All Locations)',
              style: TextStyle(
                color: isDisabled ? _textHint : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared settings card ───────────────────────────────────────────────────
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
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: _accent.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    if (subtitle != null)
                      Text(subtitle,
                          style: const TextStyle(
                              color: _textHint, fontSize: 12)),
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

  // ── Logic helpers ──────────────────────────────────────────────────────────
  Future<void> _changePassword(AuthProvider auth) async {
    if (_newPwdCtrl.text != _confirmPwdCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    if (_newPwdCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    setState(() => _isChangingPwd = true);
    final err =
        await auth.changePassword(_oldPwdCtrl.text, _newPwdCtrl.text);
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out',
            style: TextStyle(color: _textPrimary)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: _textSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: _accent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.red)),
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