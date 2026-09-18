import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../constants/app_colors.dart';

/// Plays a remote harvest video URL with play/pause controls.
class HarvestVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double height;

  const HarvestVideoPlayer({
    super.key,
    required this.videoUrl,
    this.height = 220,
  });

  @override
  State<HarvestVideoPlayer> createState() => _HarvestVideoPlayerState();
}

class _HarvestVideoPlayerState extends State<HarvestVideoPlayer> {
  VideoPlayerController? _controller;
  String? _error;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant HarvestVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _init();
    }
  }

  Future<void> _init() async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await controller.initialize();
      controller.setLooping(true);
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load harvest video.';
          _initializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(_error!, style: const TextStyle(color: AppColors.onSurfaceVariant)),
      );
    }
    if (_initializing || _controller == null || !_controller!.value.isInitialized) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final c = _controller!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: Icon(
                    c.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      c.value.isPlaying ? c.pause() : c.play();
                    });
                  },
                ),
              ),
            ),
            const Positioned(
              top: 8,
              left: 8,
              child: Chip(
                label: Text('Harvest video', style: TextStyle(fontSize: 11)),
                backgroundColor: Colors.black54,
                labelStyle: TextStyle(color: Colors.white),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
