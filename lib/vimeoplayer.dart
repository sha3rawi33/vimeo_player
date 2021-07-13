library vimeoplayer;

import 'package:Arab_Medicine_App/models/common_functions.dart';
import 'package:Arab_Medicine_App/providers/auth.dart';
import 'package:Arab_Medicine_App/providers/trust.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'src/quality_links.dart';
import 'dart:async';
import 'src/fullscreen_player.dart';

class VimeoPlayer extends StatefulWidget {
  final String id;
  final bool autoPlay;
  final bool looping;
  final int position;

  VimeoPlayer({
    @required this.id,
    this.autoPlay,
    this.looping,
    this.position,
    Key key,
  }) : super(key: key);

  @override
  _VimeoPlayerState createState() => _VimeoPlayerState(id, autoPlay, looping, position);
}

class _VimeoPlayerState extends State<VimeoPlayer> {
  String _id;
  bool autoPlay = false;
  bool looping = false;
  bool _overlay = true;
  bool fullScreen = false;
  int position;

  static const allSpeeds = <double>[1, 1.25, 1.5, 1.75, 2, 2.25, 2.5];

  _VimeoPlayerState(this._id, this.autoPlay, this.looping, this.position);

  VideoPlayerController _controller;
  Future<void> initFuture;

  QualityLinks _quality;
  Map _qualityValues;
  var _qualityValue;

  bool _seek = false;

  double videoHeight;
  double videoWidth;
  double videoMargin;

  double doubleTapRMargin = 36;
  double doubleTapRWidth = 400;
  double doubleTapRHeight = 160;
  double doubleTapLMargin = 10;
  double doubleTapLWidth = 400;
  double doubleTapLHeight = 160;
  Timer timer;

  @override
  void initState() {
    _quality = QualityLinks(_id);
    Screen.keepOn(true);

    _quality.getQualitiesSync().then((value) {
      _qualityValues = value;
      _qualityValue = value["360p"] != null ? value["360p"] : value["480p"] != null ? value["480p"] : value["540p"];
      print("PLAYING AT $_qualityValue");
      _controller = VideoPlayerController.network(_qualityValue);
      _controller.setLooping(looping);
      if (autoPlay) _controller.play();
      initFuture = _controller.initialize();

      setState(() {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
        Screen.keepOn(true);
      });
    });
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    Screen.keepOn(true);
    super.initState();
    timer = Timer.periodic(Duration(seconds: 5), (Timer t) => (){
      trustMe(context);
      secureMe();
    });
  }

  @override
  Widget build(BuildContext context) {
    secureMe();
    Screen.keepOn(true);
    final user = Provider.of<Auth>(context, listen: false).user;
    return Center(
        child: Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        GestureDetector(
          child: FutureBuilder(
              future: initFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  double delta = MediaQuery.of(context).size.width - MediaQuery.of(context).size.height * _controller.value.aspectRatio;
                  if (MediaQuery.of(context).orientation == Orientation.portrait || delta < 0) {
                    videoHeight = MediaQuery.of(context).size.width / _controller.value.aspectRatio;
                    videoWidth = MediaQuery.of(context).size.width;
                    videoMargin = 0;
                  } else {
                    videoHeight = MediaQuery.of(context).size.height;
                    videoWidth = videoHeight * _controller.value.aspectRatio;
                    videoMargin = (MediaQuery.of(context).size.width - videoWidth) / 2;
                  }
                  if (_seek && _controller.value.duration.inSeconds > 2) {
                    _controller.seekTo(Duration(seconds: position));
                    _seek = false;
                  }
                  return Stack(
                    children: <Widget>[
                      Container(
                        height: videoHeight,
                        width: videoWidth,
                        margin: EdgeInsets.only(left: videoMargin),
                        child: Stack(
                          children: [
                            VideoPlayer(_controller),
                            Transform.rotate(
                              angle: -0.45,
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: 0.1,
                                  child: Container(
                                    child: FittedBox(
                                        child: Text(
                                      user.email,
                                      style: TextStyle(color: Colors.black, fontSize: 35, fontWeight: FontWeight.w400),
                                    )),
                                    width: MediaQuery.of(context).size.width,
                                    alignment: Alignment.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _videoOverlay(),
                    ],
                  );
                } else {
                  return Center(
                      heightFactor: 6,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22A3D2)),
                      ));
                }
              }),
          onTap: () {
            setState(() {
              _overlay = !_overlay;
              if (_overlay) {
                doubleTapRHeight = videoHeight - 36;
                doubleTapLHeight = videoHeight - 10;
                doubleTapRMargin = 36;
                doubleTapLMargin = 10;
              } else if (!_overlay) {
                doubleTapRHeight = videoHeight + 36;
                doubleTapLHeight = videoHeight + 16;
                doubleTapRMargin = 0;
                doubleTapLMargin = 0;
              }
            });
          },
        ),
        GestureDetector(
            child: Container(
              width: doubleTapLWidth / 2 - 30,
              height: doubleTapLHeight - 46,
              margin: EdgeInsets.fromLTRB(0, 10, doubleTapLWidth / 2 + 30, doubleTapLMargin + 20),
              decoration: BoxDecoration(
                  //color: Colors.red,
                  ),
            ),
            onTap: () {
              setState(() {
                _overlay = !_overlay;
                if (_overlay) {
                  doubleTapRHeight = videoHeight - 36;
                  doubleTapLHeight = videoHeight - 10;
                  doubleTapRMargin = 36;
                  doubleTapLMargin = 10;
                } else if (!_overlay) {
                  doubleTapRHeight = videoHeight + 36;
                  doubleTapLHeight = videoHeight + 16;
                  doubleTapRMargin = 0;
                  doubleTapLMargin = 0;
                }
              });
            },
            onDoubleTap: () {
              setState(() {
                _controller.seekTo(Duration(seconds: _controller.value.position.inSeconds - 10));
              });
            }),
        GestureDetector(
            child: Container(
              width: doubleTapRWidth / 2 - 45,
              height: doubleTapRHeight - 60,
              margin: EdgeInsets.fromLTRB(doubleTapRWidth / 2 + 45, doubleTapRMargin, 0, doubleTapRMargin + 20),
              decoration: BoxDecoration(
                  //color: Colors.red,
                  ),
            ),
            onTap: () {
              setState(() {
                _overlay = !_overlay;
                if (_overlay) {
                  doubleTapRHeight = videoHeight - 36;
                  doubleTapLHeight = videoHeight - 10;
                  doubleTapRMargin = 36;
                  doubleTapLMargin = 10;
                } else if (!_overlay) {
                  doubleTapRHeight = videoHeight + 36;
                  doubleTapLHeight = videoHeight + 16;
                  doubleTapRMargin = 0;
                  doubleTapLMargin = 0;
                }
              });
            },
            onDoubleTap: () {
              setState(() {
                _controller.seekTo(Duration(seconds: _controller.value.position.inSeconds + 10));
              });
            }),
      ],
    ));
  }

  void _settingModalBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          final children = <Widget>[];
          _qualityValues.forEach((elem, value) => (children.add(new ListTile(
              title: new Text(" ${elem.toString()}"),
              onTap: () => {
                    setState(() {
                      _controller.pause();
                      _qualityValue = value;
                      _controller = VideoPlayerController.network(_qualityValue);
                      _controller.setLooping(true);
                      _seek = true;
                      initFuture = _controller.initialize();
                      _controller.play();
                    }),
                  }))));
          //Вывод элементов качество списком
          return Container(
            child: Wrap(
              children: children,
            ),
          );
        });
  }

  Widget _videoOverlay() {
    return _overlay
        ? Stack(
            children: <Widget>[
              GestureDetector(
                child: Center(
                  child: Container(
                    width: videoWidth,
                    height: videoHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [const Color(0x662F2C47), const Color(0x662F2C47)],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: IconButton(
                    padding: EdgeInsets.only(left: videoWidth / 2 - 30, right: videoWidth / 2 - 30, top: videoHeight / 2 - 30, bottom: videoHeight / 2 - 30),
                    icon: _controller.value.isPlaying ? Icon(Icons.pause, size: 60.0) : Icon(Icons.play_arrow, size: 60.0),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying ? _controller.pause() : _controller.play();
                      });
                    }),
              ),
              Container(
                margin: EdgeInsets.only(top: videoHeight - 70, left: videoWidth + videoMargin - 50),
                child: IconButton(
                    alignment: AlignmentDirectional.center,
                    icon: Icon(Icons.fullscreen, size: 30.0),
                    onPressed: () async {
                      setState(() {
                        _controller.pause();
                      });
                      position = await Navigator.push(
                          context,
                          PageRouteBuilder(
                              opaque: false,
                              pageBuilder: (BuildContext context, _, __) => FullscreenPlayer(
                                  id: _id,
                                  autoPlay: true,
                                  controller: _controller,
                                  position: _controller.value.position.inSeconds,
                                  initFuture: initFuture,
                                  qualityValue: _qualityValue),
                              transitionsBuilder: (___, Animation<double> animation, ____, Widget child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(scale: animation, child: child),
                                );
                              }));
                      setState(() {
                        _controller.play();
                        _seek = true;
                      });
                    }),
              ),
              Container(
                margin: EdgeInsets.only(left: videoWidth + videoMargin - 85),
                child: PopupMenuButton<double>(
                  initialValue: _controller.value.playbackSpeed,
                  tooltip: 'Playback speed',
                  onSelected: _controller.setPlaybackSpeed,
                  itemBuilder: (context) => allSpeeds
                      .map<PopupMenuEntry<double>>((speed) => PopupMenuItem(
                            value: speed,
                            child: Text('${speed}x'),
                          ))
                      .toList(),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Icon(Icons.speed_sharp, size: 26.0),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: videoWidth + videoMargin - 48),
                child: IconButton(
                    icon: Icon(Icons.settings, size: 26.0),
                    onPressed: () {
                      position = _controller.value.position.inSeconds;
                      _seek = true;
                      _settingModalBottomSheet(context);
                      setState(() {});
                    }),
              ),
              Container(
                //===== Ползунок =====//
                margin: EdgeInsets.only(top: videoHeight - 26, left: videoMargin), //CHECK IT
                child: _videoOverlaySlider(),
              )
            ],
          )
        : Center(
            child: Container(
              height: 5,
              width: videoWidth,
              margin: EdgeInsets.only(top: videoHeight - 5),
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Color(0xFF22A3D2),
                  backgroundColor: Color(0x5515162B),
                  bufferedColor: Color(0x5583D8F7),
                ),
                padding: EdgeInsets.only(top: 2),
              ),
            ),
          );
  }

  Widget _videoOverlaySlider() {
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, VideoPlayerValue value, child) {
        if (!value.hasError && value.isInitialized) {
          return Row(
            children: <Widget>[
              Container(
                width: 46,
                alignment: Alignment(0, 0),
                child: Text(value.position.inMinutes.toString() + ':' + (value.position.inSeconds - value.position.inMinutes * 60).toString()),
              ),
              Container(
                height: 20,
                width: videoWidth - 92,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Color(0xFF22A3D2),
                    backgroundColor: Color(0x5515162B),
                    bufferedColor: Color(0x5583D8F7),
                  ),
                  padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                ),
              ),
              Container(
                width: 46,
                alignment: Alignment(0, 0),
                child: Text(value.duration.inMinutes.toString() + ':' + (value.duration.inSeconds - value.duration.inMinutes * 60).toString()),
              ),
            ],
          );
        } else {
          return Container();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    timer?.cancel();
    super.dispose();
  }
}
