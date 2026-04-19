import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

/// Widget per mostrare un'anteprima video con pulsante play
/// Quando premuto, apre il video a schermo intero
class VideoHeader extends StatelessWidget {
  final String videoUrl;
  final String? fallbackImageUrl;
  final List<Color> gradientColors;
  final double height;

  const VideoHeader({
    super.key,
    required this.videoUrl,
    this.fallbackImageUrl,
    required this.gradientColors,
    this.height = 300,
  });

  void _openFullscreenVideo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FullscreenVideoPlayer(videoUrl: videoUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullscreenVideo(context),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: fallbackImageUrl == null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                )
              : null,
          image: fallbackImageUrl != null
              ? DecorationImage(
                  image: NetworkImage(fallbackImageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 56,
            ),
          ),
        ),
      ),
    );
  }
}

/// Player video a schermo intero
class FullscreenVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const FullscreenVideoPlayer({super.key, required this.videoUrl});

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        showControls: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: false,
        allowFullScreen: false, // Siamo già a schermo intero
        errorBuilder: (context, errorMessage) {
          return _buildErrorWidget();
        },
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Impossibile caricare il video',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    // Ripristina l'orientamento normale
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: _hasError
          ? _buildErrorWidget()
          : !_isInitialized
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: Chewie(controller: _chewieController!),
                  ),
                ),
    );
  }
}

/// Widget per mostrare video o immagine come sfondo dell'header
class EventHeaderBackground extends StatelessWidget {
  final String? videoUrl;
  final String? imageUrl;
  final List<Color> gradientColors;
  final Widget? overlay;

  const EventHeaderBackground({
    super.key,
    this.videoUrl,
    this.imageUrl,
    required this.gradientColors,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    final hasVideo = videoUrl != null && videoUrl!.isNotEmpty;

    if (hasVideo) {
      return Stack(
        fit: StackFit.expand,
        children: [
          VideoHeader(
            videoUrl: videoUrl!,
            fallbackImageUrl: imageUrl,
            gradientColors: gradientColors,
          ),
          // L'overlay ora non blocca più il tap perché VideoHeader ha il suo GestureDetector
          if (overlay != null) IgnorePointer(child: overlay!),
        ],
      );
    }

    // Fallback a immagine o gradiente
    return Container(
      decoration: BoxDecoration(
        gradient: imageUrl == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              )
            : null,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: overlay,
    );
  }
}
