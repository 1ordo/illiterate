import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/check_request.dart';
import '../providers/grammar_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/common/glass_card.dart';
import '../widgets/common/gradient_button.dart';
import '../widgets/common/animated_counter.dart';
import '../widgets/issue_list/modern_issue_card.dart';
import '../widgets/rewrites/modern_rewrite_card.dart';
import '../widgets/diff/text_diff_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _pulseController;
  bool _showResults = false;
  int _viewMode = 1; // 0 = Original, 1 = Corrected, 2 = Diff

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _checkGrammar() {
    if (_textController.text.trim().isEmpty) return;

    final settings = ref.read(settingsProvider);
    final request = CheckRequest(
      text: _textController.text,
      language: settings.language,
      mode: settings.mode,
      tone: settings.tone,
      includeExplanations: true,
    );

    ref.read(grammarProvider.notifier).checkGrammar(request);
    setState(() => _showResults = true);
  }

  void _clearText() {
    _textController.clear();
    ref.read(grammarProvider.notifier).clear();
    setState(() => _showResults = false);
  }

  @override
  Widget build(BuildContext context) {
    final grammarState = ref.watch(grammarProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : AppTheme.lightGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                child: _buildAppBar(context, isDark),
              ),

              // Main Content
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),

                    // Hero Section
                    if (!_showResults) ...[
                      _buildHeroSection(context, isDark),
                      const SizedBox(height: 32),
                    ],

                    // Language & Mode Selector
                    _buildQuickSettings(context, settings, isDark),
                    const SizedBox(height: 20),

                    // Text Input
                    _buildTextInput(context, isDark, grammarState),
                    const SizedBox(height: 20),

                    // Action Button
                    _buildActionButton(context, grammarState),
                    const SizedBox(height: 24),

                    // Results Section
                    if (_showResults) ...[
                      _buildResultsSection(context, grammarState, isDark),
                    ],

                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Logo icon only + text name
          Row(
            children: [
              Image.asset(
                'assets/images/ileterate-logo-only.png',
                height: 32,
              ),
              const SizedBox(width: 10),
              Text(
                'ileterate',
                style: AppTheme.titleLarge.copyWith(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Settings Button
          GestureDetector(
            onTap: () => _showSettingsModal(context, isDark),
            child: GlassCard(
              padding: const EdgeInsets.all(10),
              borderRadius: 12,
              child: Icon(
                Iconsax.setting_2,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 32),

        // Illustration
        SvgPicture.asset(
          'assets/images/writing_illustration.svg',
          height: 180,
        )
            .animate()
            .fadeIn(duration: 800.ms, delay: 200.ms)
            .scale(begin: const Offset(0.8, 0.8)),

        const SizedBox(height: 24),

        // Title
        ShaderMask(
          shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            'Write with Confidence',
            style: AppTheme.headlineLarge.copyWith(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Perfect your writing with AI-powered grammar and style checking',
          style: AppTheme.bodyLarge.copyWith(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickSettings(BuildContext context, SettingsState settings, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language Selection - Inline chips
        Text(
          'Language',
          style: AppTheme.labelLarge.copyWith(
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _languages.map((lang) {
              final isSelected = settings.language == lang['code'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    ref.read(settingsProvider.notifier).setLanguage(lang['code']!);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppTheme.primaryGradient : null,
                      color: isSelected ? null : (isDark ? Colors.white.withOpacity(0.08) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      boxShadow: isSelected ? AppTheme.glowShadow : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(lang['flag']!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          lang['name']!,
                          style: AppTheme.labelLarge.copyWith(
                            color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Mode Selection - Two buttons
        Row(
          children: [
            Expanded(
              child: _buildQuickModeButton(
                'Grammar Check',
                Iconsax.shield_tick,
                settings.checkMode == 'strict',
                () => ref.read(settingsProvider.notifier).setCheckMode('strict'),
                isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickModeButton(
                'Style & Tone',
                Iconsax.lamp_on,
                settings.checkMode == 'style',
                () => ref.read(settingsProvider.notifier).setCheckMode('style'),
                isDark,
              ),
            ),
          ],
        ),

        // Tone Selection - Only visible in Style mode
        if (settings.checkMode == 'style') ...[
          const SizedBox(height: 16),
          Text(
            'Writing Tone',
            style: AppTheme.labelLarge.copyWith(
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: Tone.values.map((tone) {
                final isSelected = settings.tone == tone;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(settingsProvider.notifier).setTone(tone);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.accentGradient : null,
                        color: isSelected ? null : (isDark ? Colors.white.withOpacity(0.08) : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.accentCyan.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        tone.displayName,
                        style: AppTheme.labelLarge.copyWith(
                          color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickModeButton(String label, IconData icon, bool isSelected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.accentGradient : null,
          color: isSelected ? null : (isDark ? Colors.white.withOpacity(0.08) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentCyan.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.labelLarge.copyWith(
                color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput(
    BuildContext context,
    bool isDark,
    GrammarState grammarState,
  ) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Text Field Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Icon(
                  Iconsax.edit_2,
                  size: 18,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 8),
                Text(
                  'Enter your text',
                  style: AppTheme.labelLarge.copyWith(
                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  ),
                ),
                const Spacer(),
                if (_textController.text.isNotEmpty)
                  IconButton(
                    onPressed: _clearText,
                    icon: const Icon(Iconsax.close_circle, size: 20),
                    color: const Color(0xFF94A3B8),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          // Text Field - Fixed padding and constraints
          Container(
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              minLines: 5,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              style: AppTheme.bodyLarge.copyWith(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText: 'Type or paste your text here...',
                hintStyle: AppTheme.bodyLarge.copyWith(
                  color: const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          const SizedBox(height: 8),

          // Character Count
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${_textController.text.length} characters',
                  style: AppTheme.bodyMedium.copyWith(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (grammarState.isLoading)
                  Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            AppTheme.primaryPurple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Analyzing...',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryPurple,
                          fontSize: 12,
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

  Widget _buildActionButton(BuildContext context, GrammarState grammarState) {
    final settings = ref.watch(settingsProvider);
    final isStyleMode = settings.checkMode == 'style';
    final buttonText = isStyleMode ? 'Check Style & Tone' : 'Check Grammar';
    final buttonIcon = isStyleMode ? Iconsax.lamp_on : Iconsax.magic_star;

    return GradientButton(
      onPressed: grammarState.isLoading ? null : _checkGrammar,
      gradient: isStyleMode ? AppTheme.accentGradient : AppTheme.primaryGradient,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (grammarState.isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          else
            Icon(buttonIcon, size: 20, color: Colors.white),
          const SizedBox(width: 12),
          Text(
            grammarState.isLoading ? 'Analyzing...' : buttonText,
            style: AppTheme.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(
    BuildContext context,
    GrammarState grammarState,
    bool isDark,
  ) {
    if (grammarState.isLoading) {
      return _buildLoadingState();
    }

    if (grammarState.error != null) {
      return _buildErrorState(grammarState.error!);
    }

    final result = grammarState.result;
    if (result == null) return const SizedBox.shrink();

    final hasChanges = result.correctedText != result.originalText;
    final issueCount = result.issues.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Corrected Text Card with Toggle
        if (hasChanges) ...[
          _buildTextComparisonSection(result, isDark),
          const SizedBox(height: 24),
        ],

        // Issues List
        if (result.issues.isNotEmpty) ...[
          _buildSectionHeader(
            issueCount == 1 ? '1 Suggestion' : '$issueCount Suggestions',
            Iconsax.message_text,
            isDark,
          ),
          const SizedBox(height: 12),
          ...result.issues.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ModernIssueCard(
                issue: entry.value,
                index: entry.key,
                onApplyFix: (suggestion) {
                  _applyFix(entry.value, suggestion);
                },
              ),
            );
          }),
          const SizedBox(height: 24),
        ],

        // Rewrites
        if (result.rewrites.isNotEmpty) ...[
          _buildSectionHeader('Style Suggestions', Iconsax.lamp_on, isDark),
          const SizedBox(height: 12),
          ...result.rewrites.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ModernRewriteCard(
                rewrite: entry.value,
                index: entry.key,
                onApply: () {
                  _textController.text = entry.value.text;
                  _checkGrammar();
                },
              ),
            );
          }),
        ],

        // No issues found
        if (result.issues.isEmpty &&
            result.correctedText == result.originalText) ...[
          _buildSuccessState(),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTheme.titleMedium.copyWith(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildTextComparisonSection(dynamic result, bool isDark) {
    final originalText = result.originalText as String;
    final correctedText = result.correctedText as String;

    String displayText;
    switch (_viewMode) {
      case 0:
        displayText = originalText;
        break;
      case 1:
        displayText = correctedText;
        break;
      default:
        displayText = correctedText;
    }

    final viewTitles = ['Original Text', 'Corrected Text', 'View Changes'];
    final viewIcons = [Iconsax.document_text, Iconsax.tick_circle, Iconsax.arrow_swap];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Toggle
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                viewIcons[_viewMode],
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              viewTitles[_viewMode],
              style: AppTheme.titleMedium.copyWith(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Toggle Buttons Row
        GlassCard(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _buildViewToggleButton('Original', 0, isDark),
              _buildViewToggleButton('Corrected', 1, isDark),
              _buildViewToggleButton('Diff', 2, isDark),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Text Card
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _viewMode == 2
                  ? _buildDiffView(originalText, correctedText, isDark)
                      .animate(key: const ValueKey('diff'))
                      .slideX(begin: 0.02, duration: 200.ms, curve: Curves.easeOut)
                  : SelectableText(
                      displayText,
                      key: ValueKey('text_$_viewMode'),
                      style: AppTheme.bodyLarge.copyWith(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        height: 1.6,
                      ),
                    )
                      .animate(key: ValueKey('anim_$_viewMode'))
                      .slideX(begin: 0.02, duration: 200.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _viewMode == 0 ? originalText : correctedText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Copied to clipboard'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Iconsax.copy, size: 18),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _textController.text = correctedText;
                        setState(() => _showResults = false);
                      },
                      icon: const Icon(Iconsax.tick_circle, size: 18),
                      label: const Text('Apply Fix'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggleButton(String label, int mode, bool isDark) {
    final isActive = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive ? AppTheme.primaryGradient : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.labelLarge.copyWith(
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.white54 : const Color(0xFF64748B)),
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiffView(String original, String corrected, bool isDark) {
    return TextDiffView(
      key: const ValueKey('diff'),
      original: original,
      corrected: corrected,
      showInline: true,
    );
  }

  Widget _buildLoadingState() {
    return GlassCard(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryPurple),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing your text...',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'AI is checking grammar, spelling, and style',
            style: AppTheme.bodyMedium.copyWith(color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.warning_2,
              color: AppTheme.errorRed,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTheme.bodyMedium.copyWith(color: const Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _checkGrammar,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return SizedBox(
      width: double.infinity,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentCyan.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Iconsax.tick_circle,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.accentGradient.createShader(bounds),
              child: Text(
                'Perfect!',
                style: AppTheme.headlineMedium.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No grammar or spelling issues found.\nYour text is ready to go!',
              style: AppTheme.bodyMedium.copyWith(color: const Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  void _applyFix(dynamic issue, String suggestion) {
    final text = _textController.text;
    final newText = text.substring(0, issue.offset) +
        suggestion +
        text.substring(issue.offset + issue.length);
    _textController.text = newText;
    _checkGrammar();
  }

  void _showLanguageModal(BuildContext context, SettingsState settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Language', style: AppTheme.titleLarge),
            const SizedBox(height: 16),
            ..._languages.map((lang) => ListTile(
                  leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                  title: Text(lang['name']!),
                  trailing: settings.language == lang['code']
                      ? const Icon(Iconsax.tick_circle, color: AppTheme.primaryPurple)
                      : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).setLanguage(lang['code']!);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _toggleMode(SettingsState settings) {
    final newMode = settings.checkMode == 'strict' ? 'style' : 'strict';
    ref.read(settingsProvider.notifier).setCheckMode(newMode);
  }

  void _showSettingsModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final currentSettings = ref.watch(settingsProvider);
          final currentIsDark = currentSettings.isDarkMode;

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: currentIsDark ? const Color(0xFF1E1B4B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: currentIsDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text('Settings', style: AppTheme.headlineMedium.copyWith(
                  color: currentIsDark ? Colors.white : const Color(0xFF1E293B),
                )),
                const SizedBox(height: 24),

                // Appearance Section
                _buildSettingsSection(
                  'Appearance',
                  Iconsax.paintbucket,
                  currentIsDark,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Dark Mode',
                          style: AppTheme.bodyLarge.copyWith(
                            color: currentIsDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: currentSettings.isDarkMode,
                        onChanged: (_) {
                          ref.read(settingsProvider.notifier).toggleDarkMode();
                        },
                        activeColor: AppTheme.accentCyan,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Language Section
                _buildSettingsSection(
                  'Default Language',
                  Iconsax.global,
                  currentIsDark,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _languages.map((lang) {
                      final isSelected = currentSettings.language == lang['code'];
                      return GestureDetector(
                        onTap: () {
                          ref.read(settingsProvider.notifier).setLanguage(lang['code']!);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppTheme.primaryGradient : null,
                            color: isSelected ? null : (currentIsDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(lang['flag']!, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                lang['name']!,
                                style: AppTheme.labelLarge.copyWith(
                                  color: isSelected ? Colors.white : (currentIsDark ? Colors.white : const Color(0xFF1E293B)),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // About Section
                _buildSettingsSection(
                  'About',
                  Iconsax.info_circle,
                  currentIsDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ilterate v1.0.0',
                        style: AppTheme.bodyLarge.copyWith(
                          color: currentIsDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI-powered writing assistant',
                        style: AppTheme.bodyMedium.copyWith(
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, bool isDark, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryPurple),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTheme.titleMedium.copyWith(
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  String _getLanguageName(String code) {
    return _languages.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'name': code.toUpperCase()},
    )['name']!;
  }

  static const _languages = [
    {'code': 'nl', 'name': 'Dutch', 'flag': '🇳🇱'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'de', 'name': 'German', 'flag': '🇩🇪'},
    {'code': 'fr', 'name': 'French', 'flag': '🇫🇷'},
    {'code': 'es', 'name': 'Spanish', 'flag': '🇪🇸'},
  ];
}
