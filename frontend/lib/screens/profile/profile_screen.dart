// lib/screens/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_button.dart';
import '../auth/login_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../profile/report_summary_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {

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

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _navy     = Color(0xFF001233);
  static const Color _navyMid  = Color(0xFF002D72);
  static const Color _blue     = Color(0xFF023E8A);
  static const Color _blueMid  = Color(0xFF0077B6);
  static const Color _gold     = Color(0xFFFFD700);
  static const Color _goldDeep = Color(0xFFFFB800);
  static const Color _pageBg   = Color(0xFFF5F8FF);
  static const Color _textMain = Color(0xFF001845);
  static const Color _textSub  = Color(0xFF90A4C4);
  static const Color _inputBg  = Color(0xFFF0F6FF);

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _shimmerController;
  late Animation<double>   _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _oldPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // ── Report helpers (logic unchanged) ──────────────────────────────────────

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
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
      if (res.statusCode != 200) {
        final body = jsonDecode(res.body);
        _showSnack(body['error'] ?? 'Download failed', isSuccess: false);
        return;
      }
      final dir    = await getTemporaryDirectory();
      final file   = File('${dir.path}/$filename');
      await file.writeAsBytes(res.bodyBytes);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        _showSnack('PDF saved to ${file.path}', isSuccess: true);
      } else if (mounted) {
        _showSnack('Report opened', isSuccess: true);
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
      backgroundColor: isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent));

    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        final user = auth.user;
        if (user == null) {
          return Scaffold(
            backgroundColor: _pageBg,
            appBar: _buildAppBar(),
            body: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Stack(alignment: Alignment.center, children: [
                  Container(width: 88, height: 88,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          border: Border.all(color: _gold.withValues(alpha: 0.35), width: 1.5))),
                  Container(
                    width: 75, height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                          colors: [Color(0xFF0A4FA3), _navy], center: Alignment(-0.3, -0.3)),
                    ),
                    child: const Icon(Icons.person_off_outlined, size: 28, color: _gold),
                  ),
                ]),
                const SizedBox(height: 20),
                const Text('Not logged in', style: TextStyle(color: _textSub, fontSize: 15)),
                const SizedBox(height: 16),
                GradientButton(
                  label: 'Sign In',
                  icon: Icons.login,
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
              ]),
            ),
          );
        }

        return Scaffold(
          backgroundColor: _pageBg,
          appBar: _buildAppBar(actions: [
            GestureDetector(
              onTap: _confirmLogout,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFC62828).withValues(alpha: 0.6), width: 1),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B), size: 13),
                  SizedBox(width: 5),
                  Text('LOGOUT', style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 10,
                      fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                ]),
              ),
            ),
          ]),
          body: Column(children: [
            _buildHero(user),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(children: [
                  _buildExpertiseSection(auth, user),
                  const SizedBox(height: 14),
                  _buildVoiceSettings(),
                  const SizedBox(height: 14),
                  _buildChangePassword(auth),
                  const SizedBox(height: 14),
                  _buildAccountInfo(user),
                  const SizedBox(height: 14),
                  _buildReportSection(),
                  const SizedBox(height: 20),
                  // Sign-out button
                  GestureDetector(
                    onTap: _confirmLogout,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC62828).withValues(alpha: 0.4), width: 1.5),
                        boxShadow: [BoxShadow(color: const Color(0xFFC62828).withValues(alpha: 0.08), blurRadius: 8)],
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.logout, color: Color(0xFFC62828), size: 18),
                        SizedBox(width: 8),
                        Text('Sign Out', style: TextStyle(color: Color(0xFFC62828),
                            fontWeight: FontWeight.w700, fontSize: 14)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar({List<Widget>? actions}) {
    return AppBar(
      backgroundColor: _navy,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _gold.withValues(alpha: 0.6), width: 1),
            color: Colors.white.withValues(alpha: 0.08),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
        ),
      ),
      title: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _gold, width: 1.5),
            color: Colors.white.withValues(alpha: 0.08),
          ),
          child: const Icon(Icons.person_outlined, size: 16, color: _gold),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('MY PROFILE', style: TextStyle(color: Colors.white, fontSize: 12,
                fontWeight: FontWeight.w800, letterSpacing: 2.0)),
            Text('Account & settings', style: TextStyle(color: _gold, fontSize: 10,
                fontWeight: FontWeight.w400, letterSpacing: 1.2)),
          ],
        ),
      ]),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(
          height: 3,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_gold, Color(0xFFFFA500), _gold]),
          ),
        ),
      ),
    );
  }

  // ── Hero — profile header ─────────────────────────────────────────────────

  Widget _buildHero(user) {
    final expertiseEmoji = AppConstants.expertiseIcons[user.expertiseLevel] ?? '📖';

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) => SizedBox(
        height: 140,
        child: Stack(children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_navy, _blue, _blueMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _MeshPainter())),
          Positioned.fill(child: CustomPaint(painter: _ShimmerPainter(_shimmer.value))),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: CustomPaint(size: const Size(double.infinity, 30), painter: _WavePainter()),
          ),
          Positioned(
            left: 20, right: 20, top: 0, bottom: 0,
            child: Row(children: [
              // Avatar
              Container(
                width: 56, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                      colors: [Color(0xFF0A4FA3), _navy], center: Alignment(-0.3, -0.3)),
                  border: Border.all(color: _gold, width: 2),
                  boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.3), blurRadius: 10)],
                ),
                child: Center(
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : user.username[0].toUpperCase(),
                    style: const TextStyle(color: _gold, fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    user.fullName.isNotEmpty ? user.fullName : user.username,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('@${user.username}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                  const SizedBox(height: 5),
                  Row(children: [
                    _heroBadge('$expertiseEmoji ${user.expertiseLevel.toUpperCase()}',
                        bg: _gold.withValues(alpha: 0.15),
                        border: _gold.withValues(alpha: 0.5),
                        textColor: _gold),
                    const SizedBox(width: 8),
                    _heroBadge('${user.totalSessions} sessions',
                        bg: Colors.white.withValues(alpha: 0.1),
                        border: Colors.white.withValues(alpha: 0.2),
                        textColor: Colors.white.withValues(alpha: 0.75)),
                  ]),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _heroBadge(String text, {required Color bg, required Color border, required Color textColor}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Text(text, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w700)),
      );

  // ── Expertise section (logic unchanged) ───────────────────────────────────

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
            child: GestureDetector(
              onTap: () async {
                final err = await auth.updateExpertiseLevel(level);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(err ?? '✅ Updated to $level'),
                    backgroundColor: err != null ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(12),
                  ));
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? _navyMid.withValues(alpha: 0.07) : _inputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? _navyMid : _textSub.withValues(alpha: 0.2),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(level.toUpperCase(),
                          style: TextStyle(
                              color: selected ? _navyMid : _textMain,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(desc, style: const TextStyle(color: _textSub, fontSize: 11)),
                    ]),
                  ),
                  if (selected)
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _navyMid),
                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                    ),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Voice settings (logic unchanged) ──────────────────────────────────────

  Widget _buildVoiceSettings() {
    return _settingsCard(
      title: 'Voice Settings',
      subtitle: 'Text-to-speech configuration',
      icon: Icons.record_voice_over,
      trailing: GestureDetector(
        onTap: () => setState(() => _showVoiceSettings = !_showVoiceSettings),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _showVoiceSettings ? _navyMid : _textSub.withValues(alpha: 0.1),
          ),
          child: Icon(
            _showVoiceSettings ? Icons.expand_less : Icons.expand_more,
            color: _showVoiceSettings ? Colors.white : _textSub, size: 16,
          ),
        ),
      ),
      child: _showVoiceSettings
          ? Column(children: [
              const SizedBox(height: 10),
              const Text(
                'Voice settings are applied in the chat. Long-press any bot message to hear it read aloud.',
                style: TextStyle(color: _textSub, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _inputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _gold.withValues(alpha: 0.3)),
                ),
                child: Column(children: [
                  _voiceTip(Icons.mic_rounded, 'Tap the mic button to speak your question'),
                  _voiceTip(Icons.volume_up_rounded, 'Tap the speaker icon on any message to hear it'),
                  _voiceTip(Icons.stop_circle_outlined, 'Tap again to stop speech'),
                ]),
              ),
            ])
          : const SizedBox.shrink(),
    );
  }

  Widget _voiceTip(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: _gold.withValues(alpha: 0.12)),
            child: Icon(icon, size: 14, color: _navyMid),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: _textSub, fontSize: 12))),
        ]),
      );

  // ── Change password (logic unchanged) ─────────────────────────────────────

  Widget _buildChangePassword(AuthProvider auth) {
    return _settingsCard(
      title: 'Change Password',
      subtitle: 'Update your account password',
      icon: Icons.lock_outline,
      trailing: GestureDetector(
        onTap: () => setState(() => _showChangePassword = !_showChangePassword),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _showChangePassword ? _navyMid : _textSub.withValues(alpha: 0.1),
          ),
          child: Icon(
            _showChangePassword ? Icons.expand_less : Icons.expand_more,
            color: _showChangePassword ? Colors.white : _textSub, size: 16,
          ),
        ),
      ),
      child: _showChangePassword
          ? Column(children: [
              const SizedBox(height: 12),
              _pwdField(_oldPwdCtrl, 'Current Password', _obscureOld,
                  () => setState(() => _obscureOld = !_obscureOld)),
              const SizedBox(height: 10),
              _pwdField(_newPwdCtrl, 'New Password', _obscureNew,
                  () => setState(() => _obscureNew = !_obscureNew)),
              const SizedBox(height: 10),
              _pwdField(_confirmPwdCtrl, 'Confirm New Password', _obscureConfirm,
                  () => setState(() => _obscureConfirm = !_obscureConfirm)),
              const SizedBox(height: 14),
              GradientButton(
                label: 'Change Password',
                icon: Icons.lock,
                isLoading: _isChangingPwd,
                onPressed: () => _changePassword(auth),
              ),
            ])
          : const SizedBox.shrink(),
    );
  }

  Widget _pwdField(TextEditingController ctrl, String label, bool obscure, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: _textMain, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textSub, fontSize: 12),
        filled: true,
        fillColor: _inputBg,
        prefixIcon: const Icon(Icons.lock_outline, color: _navyMid, size: 18),
        suffixIcon: GestureDetector(
          onTap: toggle,
          child: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: _textSub, size: 18,
          ),
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _textSub.withValues(alpha: 0.2))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _textSub.withValues(alpha: 0.2))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _navyMid, width: 1.5)),
      ),
    );
  }

  // ── Account info (logic unchanged) ────────────────────────────────────────

  Widget _buildAccountInfo(user) {
    return _settingsCard(
      title: 'Account Information',
      icon: Icons.info_outline,
      child: Column(children: [
        _infoRow('Email', user.email),
        _infoRow('Username', '@${user.username}'),
        _infoRow('Age Group', user.ageGroup),
        if (user.lastLogin != null)
          _infoRow('Last Login', user.lastLogin!.split('T').first),
      ]),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(children: [
          Text('$label:', style: const TextStyle(color: _textSub, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: _textMain, fontWeight: FontWeight.w600, fontSize: 13),
                textAlign: TextAlign.right),
          ),
        ]),
      );

  // ── PDF Report section (logic unchanged) ──────────────────────────────────

  Widget _buildReportSection() {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        final user = auth.user;
        if (user == null) return const SizedBox.shrink();
  
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: const Border(top: BorderSide(color: _gold, width: 2.5)),
            boxShadow: [
              BoxShadow(
                color: _navyMid.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gold.withValues(alpha: 0.12),
                    border: Border.all(color: _gold.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.auto_stories_outlined,
                      color: _goldDeep, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Historical Journey Report',
                          style: TextStyle(
                              color: _textMain,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      Text('Your personalised knowledge summary',
                          style: TextStyle(color: _textSub, fontSize: 12)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 14),
  
              // ── View Report button (opens ReportSummaryScreen) ───────────
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportSummaryScreen(
                        authToken: auth.token ?? '',
                        username:  user.username,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [_navyMid, _blue, _blueMid],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _navyMid.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_stories_outlined,
                          color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text('View Report & Key Points',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white54, size: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isDisabled
              ? null
              : const LinearGradient(
                  colors: [_goldDeep, _gold, Color(0xFFFFC200)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
          color: isDisabled ? _textSub.withValues(alpha: 0.15) : null,
          boxShadow: isDisabled ? [] : [
            BoxShadow(color: _gold.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _navy.withValues(alpha: 0.12)),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(7),
                    child: CircularProgressIndicator(strokeWidth: 2, color: _navy))
                : Icon(Icons.download_for_offline_outlined,
                    color: isDisabled ? _textSub : _navy, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            isLoading ? 'Generating Full Report…' : 'Download Full Report  (All Locations)',
            style: TextStyle(
                color: isDisabled ? _textSub : _navy,
                fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ]),
      ),
    );
  }

  // ── Settings card shell ────────────────────────────────────────────────────

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: const Border(top: BorderSide(color: _gold, width: 2.5)),
        boxShadow: [
          BoxShadow(color: _navyMid.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _navyMid.withValues(alpha: 0.08),
              border: Border.all(color: _navyMid.withValues(alpha: 0.2), width: 1),
            ),
            child: Icon(icon, color: _navyMid, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(color: _textMain, fontWeight: FontWeight.w700, fontSize: 14)),
              if (subtitle != null)
                Text(subtitle, style: const TextStyle(color: _textSub, fontSize: 11)),
            ]),
          ),
          if (trailing != null) trailing,
        ]),
        child,
      ]),
    );
  }

  // ── Logic helpers (unchanged) ──────────────────────────────────────────────

  Future<void> _changePassword(AuthProvider auth) async {
    if (_newPwdCtrl.text != _confirmPwdCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    if (_newPwdCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 6 characters')));
      return;
    }
    setState(() => _isChangingPwd = true);
    final err = await auth.changePassword(_oldPwdCtrl.text, _newPwdCtrl.text);
    setState(() => _isChangingPwd = false);
    if (mounted) {
      if (err == null) {
        _oldPwdCtrl.clear();
        _newPwdCtrl.clear();
        _confirmPwdCtrl.clear();
        setState(() => _showChangePassword = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Password changed'), backgroundColor: Color(0xFF2E7D32)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: const Color(0xFFC62828)));
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(color: _textMain, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: _textSub)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: _navyMid))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: Color(0xFFC62828))),
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

// ── Painters ──────────────────────────────────────────────────────────────────

class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8;
    p.color = const Color(0xFFFFD700).withValues(alpha: 0.07);
    canvas.drawCircle(Offset(size.width * 1.05, -10), size.width * 0.55, p);
    p.color = const Color(0xFF48CAE4).withValues(alpha: 0.09);
    canvas.drawCircle(Offset(-20, size.height * 1.5), size.width * 0.5, p);
    p.color = const Color(0xFFFFFFFF).withValues(alpha: 0.03);
    p.strokeWidth = 1.0;
    for (int i = 0; i < 7; i++) {
      canvas.drawLine(Offset(size.width * i / 6, 0), Offset(size.width * i / 6 + 40, size.height), p);
    }
    final dot = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.07)..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 3; j++) {
        canvas.drawCircle(Offset(size.width - 20 - i * 20.0, 12 + j * 20.0), 1.6, dot);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment(progress - 1, 0), end: Alignment(progress, 0),
      colors: [Colors.transparent, Colors.white.withValues(alpha: 0.04), Colors.transparent],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }
  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.progress != progress;
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF5F8FF)..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height * 0.30);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.6, size.width, size.height * 0.2);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}