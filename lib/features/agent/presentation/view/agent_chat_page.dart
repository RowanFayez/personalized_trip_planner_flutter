import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/auth_service.dart';
import '../cubit/agent_cubit.dart';
import '../cubit/agent_state.dart';
import '../widgets/agent_query_chips_bar.dart';
import '../widgets/agent_sign_in_gate.dart';
import '../../../../presentation/features/auth/presentation/widgets/google_sign_in_dialog.dart';

class AgentChatPage extends StatefulWidget {
  final String? initialMessage;

  const AgentChatPage({super.key, this.initialMessage});

  @override
  State<AgentChatPage> createState() => _AgentChatPageState();
}

class _AgentChatPageState extends State<AgentChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = sl<AuthService>();
  bool _isShowingSignInDialog = false;
  bool _initialMessageSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    if (_authService.uid == null) {
      _promptSignInForChat();
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    context.read<AgentCubit>().sendMessage(text);
  }

  void _sendSuggestedQuery(String query) {
    if (_authService.uid == null) {
      _promptSignInForChat();
      return;
    }
    final text = query.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    _controller.clear();
    context.read<AgentCubit>().sendMessage(text);
  }

  void _maybeSendInitialMessage({required bool signedIn}) {
    if (_initialMessageSent) return;
    final text = widget.initialMessage?.trim();
    if (text == null || text.isEmpty) return;

    if (!signedIn) {
      if (_controller.text.trim().isEmpty) {
        _controller.text = text;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_promptSignInForChat());
      });
      return;
    }

    _initialMessageSent = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.clear();
      context.read<AgentCubit>().sendMessage(text);
    });
  }

  Future<void> _promptSignInForChat() async {
    if (!mounted || _isShowingSignInDialog) return;
    _isShowingSignInDialog = true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.agentSignInRequired,
          textDirection: TextDirection.rtl,
        ),
      ),
    );

    await showGoogleSignInDialog(context);
    _isShowingSignInDialog = false;
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    unawaited(
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object?>(
      stream: _authService.authStateChanges(),
      builder: (context, _) {
        final signedIn = _authService.uid != null;
        _maybeSendInitialMessage(signedIn: signedIn);

        return BlocConsumer<AgentCubit, AgentState>(
          listenWhen: (previous, current) =>
              previous.chatHistory.length != current.chatHistory.length ||
              previous.status != current.status,
          listener: (context, state) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _scrollToBottom(),
            );
          },
          builder: (context, state) {
            final isLoading = signedIn && state.status == AgentStatus.loading;
            final itemCount = state.chatHistory.length + (isLoading ? 1 : 0);

            return Scaffold(
              backgroundColor: AppColors.backgroundDark,
              appBar: AppBar(
                backgroundColor: AppColors.backgroundDark,
                elevation: 0,
                titleSpacing: 0,
                title: const _AgentTitle(),
                actions: [
                  IconButton(
                    tooltip: AppStrings.agentClearChatTooltip,
                    onPressed: signedIn && !isLoading
                        ? () => context.read<AgentCubit>().clearChat()
                        : null,
                    icon: Icon(Icons.refresh_rounded, size: 22.r),
                  ),
                  SizedBox(width: 6.w),
                ],
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: signedIn
                          ? ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.fromLTRB(
                                16.w,
                                10.h,
                                16.w,
                                14.h,
                              ),
                              itemCount: itemCount,
                              itemBuilder: (context, index) {
                                if (isLoading && index == itemCount - 1) {
                                  return const _TypingBubble();
                                }

                                return _MessageBubble(
                                  message: state.chatHistory[index].text,
                                  isUser: state.chatHistory[index].isUser,
                                );
                              },
                            )
                          : AgentSignInGate(onSignIn: _promptSignInForChat),
                    ),
                    if (signedIn &&
                        state.status == AgentStatus.failure &&
                        (state.errorMessage ?? '').trim().isNotEmpty)
                      _ErrorStrip(message: state.errorMessage!.trim()),
                    if (signedIn)
                      Padding(
                        padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 8.h),
                        child: AgentQueryChipsBar(
                          onQuerySelected: _sendSuggestedQuery,
                          queries: AppStrings.agentSuggestedQueries,
                        ),
                      ),
                    _Composer(
                      controller: _controller,
                      enabled: signedIn && !isLoading,
                      onSend: _send,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AgentTitle extends StatelessWidget {
  const _AgentTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38.r,
          height: 38.r,
          decoration: BoxDecoration(
            color: AppColors.searchInputBackground,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/osta_avatar.png',
              width: 38.r,
              height: 38.r,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.agentTitle,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              AppStrings.agentSubtitle,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const _MessageBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final background = isUser
        ? AppColors.primaryTeal
        : AppColors.searchInputBackground;
    final textColor = isUser ? AppColors.backgroundDark : AppColors.textPrimary;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 0.78.sw),
        child: Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18.r),
              topRight: Radius.circular(18.r),
              bottomLeft: Radius.circular(isUser ? 18.r : 4.r),
              bottomRight: Radius.circular(isUser ? 4.r : 18.r),
            ),
            border: isUser ? null : Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Text(
            message,
            textDirection: _containsArabic(message)
                ? TextDirection.rtl
                : TextDirection.ltr,
            style: TextStyle(
              color: textColor,
              fontSize: 14.sp,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  bool _containsArabic(String value) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(value);
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.searchInputBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            topRight: Radius.circular(18.r),
            bottomRight: Radius.circular(18.r),
            bottomLeft: Radius.circular(4.r),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: const _TypingDots(),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (_controller.value + (index * 0.18)) % 1.0;
            final opacity = phase < 0.5 ? 0.35 + phase : 1.35 - phase;

            return Container(
              width: 7.r,
              height: 7.r,
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(
                  alpha: opacity.clamp(0.35, 1.0),
                ),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _ErrorStrip extends StatelessWidget {
  final String message;

  const _ErrorStrip({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.42)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        14.w,
        10.h,
        14.w,
        bottomInset > 0 ? 10.h : 14.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: AppStrings.agentInputHint,
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13.sp,
                ),
                filled: true,
                fillColor: AppColors.searchInputBackground,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 13.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.r),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.r),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.r),
                  borderSide: const BorderSide(color: AppColors.primaryTeal),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          SizedBox(
            width: 48.r,
            height: 48.r,
            child: FilledButton(
              onPressed: enabled ? onSend : null,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: AppColors.primaryTeal,
                disabledBackgroundColor: AppColors.surfaceLight,
                shape: const CircleBorder(),
              ),
              child: Icon(
                Icons.send_rounded,
                color: AppColors.backgroundDark,
                size: 21.r,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
