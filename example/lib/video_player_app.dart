import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class VideoAppController {
  VoidCallback? onSeekStart;
  ValueChanged<double>? onSeek;
  VoidCallback? onSeekEnd;

/*void setOnSeekStart({required VoidCallback onSeekSt}) {
    onSeekStart = onSeekSt;
  }

  void setOnSeek({required ValueChanged<double> onSk}) {
    onSeek = onSk;
  }

  void setOnSeekEnd({required VoidCallback onSeekEd}) {
    onSeekEnd = onSeekEd;
  }*/
}

class VideoPlayerApp extends StatefulWidget {
  final String file;
  final ValueChanged<Duration>? onVideoPositionUpdated;
  final bool shouldPlay;
  final bool shouldPause;
  final bool shouldLoop;
  final bool mute;
  final bool showVolume;
  final bool showBuffer;
  final bool pauseOnTap;
  final bool showDurationBar;
  final bool allowSeekTo;
  final ValueChanged<bool>? bufferCallback;
  final bool showPlayPauseAnimation;
  final bool seekToStartAfterPause;
  final VoidCallback? onInactive;
  final VoidCallback? onResume;
  final int? trimStart;
  final int? trimEnd;
  final Duration? initialSeekTo;
  final VoidCallback? onVideoEnd;
  final double? durationBarWidth;
  final EdgeInsets? durationBarMargin;
  final VideoAppController? videoAppController;
  final double scale;
  final bool autoPlayOnVisibility;
  final double autoPlayVisibilityFactor;
  final String? thumb;
  final double? thumbWidth;
  final double? thumbHeight;
  final Offset? durationBarTranslateOffset;
  final VoidCallback? onPlay;
  final VoidCallback? onDisposeController;
  final ValueChanged<Size> onSizeChanged;
  const VideoPlayerApp(
      {super.key,
        required this.file,
        this.shouldLoop = false,
        this.shouldPause = false,
        this.shouldPlay = true,
        this.mute = false,
        this.showVolume = false,
        this.showBuffer = true,
        this.pauseOnTap = false,
        this.showDurationBar = false,
        this.seekToStartAfterPause = true,
        this.showPlayPauseAnimation = false,
        this.onInactive,
        this.onResume,
        this.bufferCallback,
        this.onVideoPositionUpdated,
        this.trimStart,
        this.trimEnd,
        this.onVideoEnd,
        this.initialSeekTo,
        this.durationBarWidth,
        this.durationBarMargin,
        this.videoAppController,
        this.allowSeekTo = true,
        this.scale = 1,
        this.autoPlayOnVisibility = false,
        this.autoPlayVisibilityFactor = 0.65,
        this.thumb,
        this.thumbWidth,
        this.thumbHeight,
        this.durationBarTranslateOffset,
        this.onPlay,
        this.onDisposeController, required this.onSizeChanged});

  @override
  _VideoPlayerAppState createState() => _VideoPlayerAppState();
}

class _VideoPlayerAppState extends State<VideoPlayerApp>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  final ValueNotifier<bool> _buffering = ValueNotifier(false);
  final ValueNotifier<double> _videoPosition = ValueNotifier(0.0);
  final GlobalKey visibilityKey = GlobalKey();

  // bool _volumeTriggered = false;
  StreamSubscription? _volumeListener;
  Duration _currentPosition = Duration.zero;
  String _file = "";
  final ValueNotifier _volumeTriggeredButton = ValueNotifier(true);

  bool initializing = false;

  Future<void> _init({bool onVisibility = false}) async {
    //print("video controller gesture : ${widget.videoAppController}");
    if (widget.videoAppController != null) {
      widget.videoAppController!.onSeekStart= onSeekStart;
      widget.videoAppController!.onSeek = onSeek;
      widget.videoAppController!.onSeekEnd = onSeekEnd;
    }

    //print("video controller gesture on seek : ${widget.videoAppController?.onSeek}");
    if (widget.file.isNotEmpty && !initializing) {
      initializing = true;
      print("init video player : $_controller");
      print(
          "File video player app is : $_file and widget file is : ${widget.file}");
      _file = widget.file;
      _controller = _file.startsWith("http")
          ? VideoPlayerController.network(widget.file,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true))
          : VideoPlayerController.file(File(widget.file),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
      try {
        await _controller!.initialize();
      } catch (error) {
        print(
            "Error initializing player ${widget.file} : $error");
      }
      final size = _controller!.value.size;
      print("WIDTH : ${size.width}");
      print("HEIGHT : ${size.height}");
      widget.onSizeChanged(_controller!.value.size);
      if (widget.initialSeekTo != null) {
        seekTo(widget.initialSeekTo!);
      }

      if (widget.mute) {
        _controller!.setVolume(0);
      } else {
        _controller!.setVolume(1);
      }
      _volumeTriggeredButton.value = widget.showVolume;
      //if (!widget.showVolume) {
      // If the device volume is already triggered we init the volume to on

      //}

      _currentPosition = _controller!.value.position;
      _controller!.addListener(_listener);

      if (widget.trimStart != null) {
        print("seek to : ${widget.trimStart}");
        seekTo(Duration(milliseconds: widget.trimStart!));
      }

      if (widget.autoPlayOnVisibility) {
        if (onVisibility) {
          _controller!.play();
          if (widget.onPlay != null) {
            widget.onPlay!();
          }
        }
      } else {
        _controller!.play();
        if (widget.onPlay != null) {
          widget.onPlay!();
        }
      }

      if (mounted) {
        setState(() {});
      }
    }
    initializing = false;
  }

  void _listener() {
    if (_controller != null) {
      bool controlBuffer = _controller!.value.isBuffering;
      if (_buffering.value != controlBuffer && mounted) {
        _buffering.value = controlBuffer;
        if (widget.bufferCallback != null) {
          widget.bufferCallback!(controlBuffer);
        }
        //print("buffer video $controlBuffer");
      }

      Duration dur = _controller!.value.position;
      if (widget.trimStart != null && widget.trimEnd != null) {
        //print("dur : ${dur.inMilliseconds}");
        //print("trim end : ${widget.trimEnd}");
        if (dur.inMilliseconds >= widget.trimEnd! ||
            dur.inMilliseconds < widget.trimStart!) {
          //print("seek to start");

          seekTo(Duration(milliseconds: widget.trimStart!));
        }
      }

      if (widget.onVideoEnd != null) {
        if (dur == _controller!.value.duration) {
          widget.onVideoEnd!();
        }
      }

      if (widget.onVideoPositionUpdated != null || widget.showDurationBar) {
        if (_currentPosition != dur) {
          _currentPosition = dur;
          if (widget.onVideoPositionUpdated != null) {
            widget.onVideoPositionUpdated!(_currentPosition);
          }
          if (widget.showDurationBar) {
            _videoPosition.value = min(
                (_currentPosition.inMilliseconds /
                    _controller!.value.duration.inMilliseconds),
                1);
            if (_videoPosition.value < 0) {
              _videoPosition.value = 0;
            }
          }
        }
      }
    }
  }

  Future<void> disposeController() async {
    if (_controller != null) {
      if (widget.onDisposeController != null) {
        widget.onDisposeController!();
      }
      //if (_controller!.value.isPlaying) _controller!.pause();
      _controller!.removeListener(_listener);
      _controller!.dispose();
      _controller = null;
      if (_volumeListener != null) {
        _volumeListener!.cancel();
        _volumeListener = null;
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (widget.shouldPlay) {
          if (widget.onResume != null) {
            widget.onResume!();
          }
          playPlayer();
        }
        break;
      case AppLifecycleState.inactive:
        if (widget.onInactive != null) {
          widget.onInactive!();
        }
        pausePlayer();
        break;
      case AppLifecycleState.paused:
      //pausePlayer();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    print("dispose video is called");
    disposeController();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    print("init sate in video player call");
    WidgetsBinding.instance.addObserver(this);
    if (!widget.autoPlayOnVisibility) {
      _init();
    }
    super.initState();
  }

  Future<void> reload() async {
    print("Reloading player...");
    await disposeController();
    _init();
  }

  void onVolumeButtonTapped() {
    if (_controller != null) {
      HapticFeedback.mediumImpact();
      if (!_volumeTriggeredButton.value) {
        _volumeTriggeredButton.value = true;
        _controller!.setVolume(1);
      } else {
        _volumeTriggeredButton.value = false;
        _controller!.setVolume(0);
      }
    }
  }

  void pauseOnTap() {
    print("pause video on tap");
    if (_controller != null) {
      if (_controller!.value.isPlaying) {
        pausePlayer();
      } else {
        playPlayer();
      }
    }
  }

  void pausePlayer() {
    if (_controller != null) {
      if (_controller!.value.isPlaying) {
        print("pause player");
        _controller!.pause();
        if (widget.showPlayPauseAnimation) {}
      }
    }
  }

  void playPlayer() {
    if (_controller != null) {
      if (!_controller!.value.isPlaying) {
        print("play player");
        _controller!.play();
        if (widget.onPlay != null) {
          widget.onPlay!();
        }
        if (widget.showPlayPauseAnimation) {}
      }
    }
  }

  void _handlePlayerState() {
    if (!mounted) {
      return;
    }
    //print("on seek callback : ${widget.videoAppController?.onSeek} : ${widget.hashCode}");
    if (widget.videoAppController != null && widget.videoAppController!.onSeek == null) {
      //print("re affect call back controller");
      widget.videoAppController!.onSeekStart = onSeekStart;
      widget.videoAppController!.onSeek = onSeek;
      widget.videoAppController!.onSeekEnd= onSeekEnd;
    }
    /* if (_file != widget.file) {
      reload();
    }*/
    if (_controller != null) {
      if (_controller!.value.isInitialized) {
        //print("video controller should play : " + (widget.shouldPlay).toString());
        //print("video controller not is playing : " + (!_controller!.value.isPlaying).toString());
        //print("video player should play : ${widget.shouldPlay}");
        //if (widget.shouldPlay && !_controller!.value.isPlaying) {
        //print("PLAY VIDEO");
        //if (widget.seekToStartAfterPause && widget.trimStart == null) {
        // print("SEEK TO START");
        //seekTo(Duration.zero);
        // }
        //_controller!.play();
        // if (widget.onPlay != null) {
        //widget.onPlay!();
        //}
        //  }
        if (widget.shouldLoop) {
          //print("LOOP VIDEO");
          if (!_controller!.value.isLooping) {
            _controller!.setLooping(true);
          }
        } else if (_controller!.value.isLooping) {
          //print("NOT LOOP VIDEO");
          _controller!.setLooping(false);
        }
        //print("video controller should pause : " + (widget.shouldPause).toString());
        //print("video controller is playing : " + (_controller!.value.isPlaying).toString());

        //if (!widget.showVolume) {
        if (widget.mute) {
          //print("VOLUME OFF VIDEO");
          _controller!.setVolume(0);
        } else {
          _controller!.setVolume(1);
        }
        //}

        if (widget.shouldPause) {
          // && _controller!.value.isPlaying) {
          print("DISPOSE VIDEO");
          //_controller!.pause();
          disposeController();
        }
      }
    } else if (!widget.shouldPause &&
        _controller == null &&
        lastFraction >= widget.autoPlayVisibilityFactor) {
      _init(onVisibility: true);
    }
  }

  double lastFraction = 0;

  @override
  Widget build(BuildContext context) {
    _handlePlayerState();
    return Stack(
        alignment: Alignment.center,
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            GestureDetector(
              onTap: widget.pauseOnTap
                  ? () {
                pauseOnTap();
              }
                  : null,
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: Stack(children: [
                  Transform.scale(
                      scale: widget.scale, child: VideoPlayer(_controller!)),
                  if (widget.showBuffer)
                    ValueListenableBuilder(
                        valueListenable: _buffering,
                        builder:
                            (BuildContext context, bool value, Widget? child) {
                          return _buffering.value
                              ? const Center()
                              : const SizedBox();
                        }),
                  if (widget.showVolume)
                    GestureDetector(
                      onTap: onVolumeButtonTapped,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: ValueListenableBuilder(
                              valueListenable: _volumeTriggeredButton,
                              builder: (context, dyn, child) => ClipOval(
                                child: Container(
                                  color: Theme.of(context).primaryColor,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      _volumeTriggeredButton.value
                                          ? CupertinoIcons.volume_up
                                          : CupertinoIcons.volume_off,
                                      //color: ThemeProvider.onDarkMode ? Colors.white : ThemeProvider.shadow,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              )),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
        ],
      );
  }

  void onSeek(double value) {
    if (_controller == null) return;
    final position = _controller!.value.duration * value;
    seekTo(position);
  }

  void onSeekStart() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    }
  }

  void onSeekEnd() {
    if (_controller == null) return;
    if (!_controller!.value.isPlaying) {
      _controller!.play();
      if(widget.onPlay != null) {
        widget.onPlay!();
      }
    }
  }

  void seekTo(Duration position) {
    if (_controller != null && _controller!.value.isInitialized && mounted) {
      _controller!.seekTo(position);
    }
  }
}
