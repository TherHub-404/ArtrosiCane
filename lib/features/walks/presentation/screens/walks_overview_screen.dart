import 'package:artrosi_cane/core/utils/haptics.dart';
import 'package:artrosi_cane/features/walks/data/advice_video_repository.dart';
import 'package:artrosi_cane/features/walks/domain/advice_video.dart';
import 'package:artrosi_cane/l10n/app_locale.dart';
import 'package:artrosi_cane/l10n/app_localizations.dart';
import 'package:artrosi_cane/theme/app_colors.dart';
import 'package:artrosi_cane/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

class WalksOverviewScreen extends ConsumerWidget {
  const WalksOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(adviceVideosProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            videosAsync.when(
              data: (videos) => videos.isEmpty
                  ? _WalksMessage(
                      icon: Icons.movie_outlined,
                      message: context.l10n.text(
                        'Nessun video disponibile al momento.',
                      ),
                    )
                  : _ReelsFeed(videos: videos),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              ),
              error: (_, __) => _WalksMessage(
                icon: Icons.wifi_off_rounded,
                message: context.l10n.text(
                  'Impossibile caricare i video. Controlla la connessione e riprova.',
                ),
                onRetry: () => ref.invalidate(adviceVideosProvider),
                retryLabel: context.l10n.text('Riprova'),
              ),
            ),
            // Floating back button — visible in every state.
            const Positioned(top: 6, left: 10, child: _ReelBackButton()),
          ],
        ),
      ),
    );
  }
}

class _WalksMessage extends StatelessWidget {
  const _WalksMessage({
    required this.icon,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: AppColors.primaryBlue.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5C6275),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaApricot,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  retryLabel ?? 'Riprova',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReelBackButton extends StatelessWidget {
  const _ReelBackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.primaryBlue,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reels feed: vertical snap-scrolling list of advice videos.
// ---------------------------------------------------------------------------

class _ReelsFeed extends StatefulWidget {
  const _ReelsFeed({required this.videos});

  final List<AdviceVideo> videos;

  @override
  State<_ReelsFeed> createState() => _ReelsFeedState();
}

class _ReelsFeedState extends State<_ReelsFeed> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double bottomInset = 16;
    final videos = widget.videos;

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          allowImplicitScrolling: true,
          itemCount: videos.length,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemBuilder: (context, index) {
            return _ReelPage(
              video: videos[index],
              isActive: index == _currentPage,
              bottomInset: bottomInset,
            );
          },
        ),
        // Page indicator dots on the right edge.
        if (videos.length > 1)
          Positioned(
            right: 8,
            top: 0,
            bottom: bottomInset,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < videos.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      width: 6,
                      height: i == _currentPage ? 20 : 6,
                      decoration: BoxDecoration(
                        color: i == _currentPage
                            ? AppColors.ctaApricot
                            : AppColors.primaryBlue.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ReelPage extends StatelessWidget {
  const _ReelPage({
    required this.video,
    required this.isActive,
    required this.bottomInset,
  });

  final AdviceVideo video;
  final bool isActive;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguage.fromLocale(Localizations.localeOf(context)).code;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        6,
        AppSpacing.sm,
        bottomInset,
      ),
      child: Column(
        children: [
          // Title — always fully visible: wraps onto more lines, never
          // truncated. Min height keeps it clear of the floating back button.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 56,
                  vertical: 4,
                ),
                child: Text(
                  video.titleFor(lang),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 19,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: _ReelVideoPlayer(
                  key: ValueKey(video.id),
                  url: video.url,
                  isActive: isActive,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              video.descriptionFor(lang),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5C6275),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single reel video player: autoplay on scroll, tap to pause/resume, loops.
// ---------------------------------------------------------------------------

class _ReelVideoPlayer extends StatefulWidget {
  const _ReelVideoPlayer({
    super.key,
    required this.url,
    required this.isActive,
  });

  final String url;
  final bool isActive;

  @override
  State<_ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<_ReelVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initializing = true;
  Object? _error;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) return;
      setState(() => _initializing = false);
      if (widget.isActive) {
        await controller.seekTo(Duration.zero);
        await controller.play();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _initializing = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant _ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (widget.isActive) {
      _paused = false;
      controller.seekTo(Duration.zero);
      controller.play();
    } else {
      controller.pause();
      controller.seekTo(Duration.zero);
    }
    if (mounted) setState(() {});
  }

  void _toggle() {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        !widget.isActive) {
      return;
    }
    Haptics.tap();
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
        _paused = true;
      } else {
        controller.play();
        _paused = false;
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(22));
    final controller = _controller;
    final ready =
        !_initializing &&
        _error == null &&
        controller != null &&
        controller.value.isInitialized;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox.expand(
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (ready)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  )
                else if (_error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        context.l10n.text('Video non disponibile'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                // Tap layer: pause / resume.
                if (ready)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggle,
                    ),
                  ),

                // Pause overlay icon.
                if (ready)
                  IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _paused ? 1 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.28),
                        alignment: Alignment.center,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.7),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Progress bar pinned to the bottom edge.
                if (ready)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: VideoProgressIndicator(
                      controller,
                      allowScrubbing: false,
                      padding: EdgeInsets.zero,
                      colors: VideoProgressColors(
                        playedColor: AppColors.ctaApricot,
                        bufferedColor: Colors.white.withValues(alpha: 0.28),
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
