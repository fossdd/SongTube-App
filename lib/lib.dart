// Flutter
import 'package:audio_service/audio_service.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info/package_info.dart';
import 'package:songtube/internal/nativeMethods.dart';

// Internal
import 'package:songtube/internal/updateChecker.dart';
import 'package:songtube/provider/configurationProvider.dart';
import 'package:songtube/provider/downloadsProvider.dart';
import 'package:songtube/provider/managerProvider.dart';
import 'package:songtube/provider/mediaProvider.dart';
import 'package:songtube/provider/preferencesProvider.dart';
import 'package:songtube/routes/slidableVideoPage.dart';
import 'package:songtube/screens/downloads.dart';
import 'package:songtube/screens/home.dart';
import 'package:songtube/screens/media.dart';
import 'package:songtube/screens/library.dart';
import 'package:songtube/players/musicPlayer.dart';

// Packages
import 'package:provider/provider.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:songtube/ui/components/autohideScaffold.dart';
import 'package:songtube/ui/components/navigationBar.dart';
import 'package:songtube/ui/dialogs/appUpdateDialog.dart';
import 'package:songtube/ui/dialogs/joinTelegramDialog.dart';
import 'package:songtube/ui/dialogs/loadingDialog.dart';
import 'package:songtube/ui/internal/disclaimerDialog.dart';
import 'package:songtube/ui/internal/downloadFixDialog.dart';
import 'package:songtube/ui/internal/lifecycleEvents.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Lib extends StatefulWidget {
  @override
  _LibState createState() => _LibState();
}

class _LibState extends State<Lib> {

  // Current Screen Index
  int _screenIndex;

  // This Widget ScaffoldKey
  GlobalKey<AutoHideScaffoldState> _scaffoldStateKey;
  GlobalKey<ScaffoldState> _internalScaffoldKey;

  @override
  void initState() {
    super.initState();
    _screenIndex = 0;
    _scaffoldStateKey = new GlobalKey();
    _internalScaffoldKey = GlobalKey<ScaffoldState>();
    WidgetsBinding.instance.renderView.automaticSystemUiAdjustment=false;
    KeyboardVisibility.onChange.listen((bool visible) {
        if (visible == false) FocusScope.of(context).unfocus();
      }
    );
    NativeMethod.handleIntent().then((intent) async {
      if (intent != null) {
        _handleIntent(intent);
      }
    });
    WidgetsBinding.instance.addObserver(
      new LifecycleEventHandler(resumeCallBack: () async {
        PreferencesProvider prefs = Provider.of<PreferencesProvider>(context, listen: false);
        DownloadsProvider downloads = Provider.of<DownloadsProvider>(context, listen: false);
        if (downloads.queueList.isNotEmpty ||
          downloads.downloadingList.isNotEmpty ||
          downloads.convertingList.isNotEmpty ||
          downloads.completedList.isNotEmpty
        ) {
          if (prefs.showJoinTelegramDialog && prefs.remindTelegramLater == false) {
            showDialog<void>(
              context: context,
              builder: (_) => JoinTelegramDialog()
            );
          }
        }
        String intent = await NativeMethod.handleIntent();
        if (intent == null) return;
        _handleIntent(intent);
        return;
      })
    );
    Provider.of<MediaProvider>(context, listen: false).loadSongList();
    Provider.of<MediaProvider>(context, listen: false).loadVideoList();
    // Disclaimer
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Save ScaffoldState Key
      Provider.of<ManagerProvider>(context, listen: false).scaffoldStateKey =
        this._scaffoldStateKey;
      Provider.of<ManagerProvider>(context, listen: false).internalScaffoldKey =
        this._internalScaffoldKey;
      // Show Disclaimer
      if (!Provider.of<ConfigurationProvider>(context, listen: false).disclaimerAccepted) {
        await showDialog(
          context: context,
          builder: (context) => DisclaimerDialog()
        );
      }
      if (Provider.of<ConfigurationProvider>(context, listen: false).showDownloadFixDialog) {
        AndroidDeviceInfo deviceInfo = await DeviceInfoPlugin().androidInfo;
        int sdkNumber = deviceInfo.version.sdkInt;
        if (sdkNumber >= 30) {
          await showDialog(
            context: context,
            builder: (context) => DownloadFixDialog()
          );
        }
        Provider.of<ConfigurationProvider>(context, listen: false)
          .showDownloadFixDialog = false;
      }
      // Check for Updates
      PackageInfo.fromPlatform().then((android) {
        double appVersion = double
          .parse(android.version.replaceRange(3, 5, ""));
        getLatestRelease().then((details) {
          if (appVersion < details.version) {
            // Show the user an Update is available
            showDialog(
              context: context,
              builder: (context) => AppUpdateDialog(details)
            );
          }
        });
      });
    });
    AudioService.runningStream.listen((_) {
      setState(() {});
    });
  }

  void _handleIntent(String intent) async {
    if (VideoId.parseVideoId(intent) != null) {
      String id = VideoId.parseVideoId(intent);
      showDialog(
        context: context,
        builder: (_) => LoadingDialog()
      );
      YoutubeExplode yt = YoutubeExplode();
      Video video = await yt.videos.get(id);
      Provider.of<ManagerProvider>(context, listen: false)
        .updateMediaInfoSet(video, null);
      Navigator.pop(context);
    }
    if (PlaylistId.parsePlaylistId(intent) != null) {
      String id = PlaylistId.parsePlaylistId(intent);
      showDialog(
        context: context,
        builder: (_) => LoadingDialog()
      );
      YoutubeExplode yt = YoutubeExplode();
      Playlist playlist = await yt.playlists.get(id);
      Provider.of<ManagerProvider>(context, listen: false)
        .updateMediaInfoSet(playlist, null);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    Brightness _systemBrightness = Theme.of(context).brightness;
    Brightness _statusBarBrightness = _systemBrightness == Brightness.light
      ? Brightness.dark
      : Brightness.light;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: _statusBarBrightness,
        statusBarIconBrightness: _statusBarBrightness,
        systemNavigationBarColor: Theme.of(context).cardColor,
        systemNavigationBarIconBrightness: _statusBarBrightness,
      ),
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
      child: _libBody()
    );
  }

  Widget _libBody() {
    return AutoHideScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      key: _scaffoldStateKey,
      internalKey: _internalScaffoldKey,
      body: Container(
        color: Theme.of(context).cardColor,
        child: SafeArea(
          child: Consumer2<MediaProvider, ManagerProvider>(
            builder: (context, mediaProvider, manager, child) {
              return WillPopScope(
                onWillPop: () {
                  if (manager.expandablePlayerPanelController.isPanelOpen) {
                    manager.expandablePlayerPanelController.close();
                    return Future.value(false);
                  } else if (mediaProvider.slidingPanelOpen) {
                    mediaProvider.slidingPanelOpen = false;
                    mediaProvider.panelController.close();
                    return Future.value(false);
                  } else if (manager.showSearchBar) {
                    manager.showSearchBar = false;
                    setState(() {});
                    return Future.value(false);
                  } else if (_screenIndex != 0) {
                    setState(() => _screenIndex = 0);
                    return Future.value(false);
                  } else if (_screenIndex == 0 && manager.currentHomeTab != HomeScreenTab.Home) {
                    manager.currentHomeTab = HomeScreenTab.Home;
                    return Future.value(false);
                  } else {
                    return Future.value(true);
                  }
                },
                child: child,
              );
            },
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 250),
              child: _currentScreen(_screenIndex)
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _screenIndex,
        onItemTap: (int index) {
          setState(() => _screenIndex = index);
        }
      ),
      floatingWidget: Stack(
        children: [
          Consumer<ManagerProvider>(
            builder: (context, manager, child) {
              return AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: manager.mediaInfoSet == null
                  ? child : Container(),
              );
            },
            child: SlidingPlayerPanel(
              callback: (double position) {
                _scaffoldStateKey.currentState
                  .updateInternalController(position);
              },
            ),
          ),
          Consumer<ManagerProvider>(
            builder: (context, manager, _) {
              return AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: manager?.mediaInfoSet != null
                  ? SlidableVideoPage(
                      callback: (double position) {
                        _scaffoldStateKey.currentState
                          .updateInternalController(position);
                      },
                    )
                  : Container(),
              );
            },
          )
        ],
      )
    );
  }

  Widget _currentScreen(screenIndex) {
    if (screenIndex == 0) {
      return HomeScreen();
    } else if (screenIndex == 1) {
      return DownloadTab();
    } else if (screenIndex == 2) {
      return MediaScreen();
    } else if (screenIndex == 3) {
      return LibraryScreen();
    } else {
      return Container();
    }
  }
  
}