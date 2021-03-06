import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:songtube/players/components/videoPlayer/controls.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class StreamManifestPlayer extends StatefulWidget {
  final StreamManifest manifest;
  final VideoPlayerController controller;
  final Function onVideoEnded;
  final Function onFullscreenTap;
  final bool isFullscreen;
  StreamManifestPlayer({
    @required this.manifest,
    this.controller,
    this.onVideoEnded,
    this.onFullscreenTap,
    this.isFullscreen
  });
  @override
  _StreamManifestPlayerState createState() => _StreamManifestPlayerState();
}

class _StreamManifestPlayerState extends State<StreamManifestPlayer> {

  // Player Variables (width is set automatically)
  bool hideControls = false;
  bool videoEnded = false;

  // Reverse and Forward Animation
  bool showReverse = false;
  bool showForward = false;

  // ignore: close_sinks
  final BehaviorSubject<double> _dragPositionSubject =
    BehaviorSubject.seeded(null);

  @override
  void initState() {
    super.initState();
    Wakelock.toggle(on: true);
    Future.delayed(Duration(seconds: 2), () {
      setState(() => hideControls = true);
    });
  }

  @override
  void dispose() {
    Wakelock.toggle(on: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.isFullscreen) {
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
          await SystemChrome.setEnabledSystemUIOverlays
            ([SystemUiOverlay.top, SystemUiOverlay.bottom]);
          return Future.value(false);
        } else {
          return Future.value(true);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Video Player
            Container(
              child: widget.controller.value.initialized
                ? VideoPlayer(widget.controller)
                : Container(),
            ),
            // Video PlayBack Controls & Progress Bar
            GestureDetector(
              onTap: () => setState(() => hideControls = !hideControls),
              child: VideoPlayerControls(
                progressBar: widget.controller?.value?.duration?.inMinutes != null
                  ? videoPlayerProgressBar() : Container(),
                videoTitle: null,
                playing: widget.controller.value.isPlaying,
                onPlayPause: widget.controller.value.isPlaying
                  ? () {
                      widget.controller.pause();
                      setState(() {});
                      Future.delayed(Duration(seconds: 2), () {
                        setState(() => hideControls = true);
                      });
                    }
                  : () {
                      widget.controller.play();
                      setState(() {});
                      Future.delayed(Duration(seconds: 2), () {
                        setState(() => hideControls = true);
                      });
                    },
                onExit: () => Navigator.pop(context),
                showControls: hideControls,
              ),
            ),
            Flex(
              direction: Axis.horizontal,
              children: [
                Flexible(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () => setState(() => hideControls = !hideControls),
                    onDoubleTap: () {
                      if (widget.controller.value.initialized) {
                        Duration seekNewPosition;
                        if (widget.controller.value.position < Duration(seconds: 10)) {
                          seekNewPosition = Duration.zero;
                        } else {
                          seekNewPosition = widget.controller.value.position - Duration(seconds: 10);
                        }
                        widget.controller.seekTo(seekNewPosition);
                        setState(() => showReverse = true);
                        Future.delayed(Duration(milliseconds: 250), ()
                          => setState(() => showReverse = false));
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.all(50),
                      alignment: Alignment.center,
                      color: Colors.transparent,
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 250),
                        child: showReverse
                          ? Icon(Icons.replay_10_outlined,
                              color: Colors.white,
                              size: 40)
                          : Container()
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () => setState(() => hideControls = !hideControls),
                    onDoubleTap: () {
                      if (widget.controller.value.initialized) {
                        widget.controller.seekTo(widget.controller.value.position + Duration(seconds: 10));
                        setState(() => showForward = true);
                        Future.delayed(Duration(milliseconds: 250), ()
                          => setState(() => showForward = false));
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.all(50),
                      alignment: Alignment.center,
                      color: Colors.transparent,
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 250),
                        child: showForward
                          ? Icon(Icons.forward_10_outlined,
                              color: Colors.white,
                              size: 40)
                          : Container()
                      ),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget videoPlayerProgressBar() {
    return StreamBuilder(
      stream: Rx.combineLatest2<double, double, double>(
        _dragPositionSubject.stream,
        Stream.periodic(Duration(milliseconds: 1000)),
        (dragPosition, _) => dragPosition),
      builder: (context, snapshot) {
        if (widget.controller.value.duration == widget.controller.value.position && !videoEnded) {
          videoEnded = true;
          widget.onVideoEnded();
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0, left: 8),
              child: Text(
                "${widget.controller.value.position.inMinutes.toString().padLeft(2, '0')}:" +
                "${widget.controller.value.position.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white
                ),
              ),
            ),
            Expanded(
              child: VideoProgressIndicator(
                widget.controller,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: VideoProgressColors(
                  playedColor: Theme.of(context).accentColor,
                  bufferedColor: Colors.white.withOpacity(0.6),
                  backgroundColor: Colors.white.withOpacity(0.4)
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                "${widget.controller.value.duration.inMinutes.toString().padLeft(2, '0')}:" +
                "${widget.controller.value.duration.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white
                ),
              ),
            ),
            IconButton(
              icon: Icon(widget.isFullscreen
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
                color: Colors.white
              ),
              onPressed: widget.onFullscreenTap
            )
          ],
        );
      },
    );
  }
}