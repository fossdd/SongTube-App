import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PreferencesProvider extends ChangeNotifier {

  PreferencesProvider() {
    init();
  }

  // Initialize Shared Preferences
  void init() async {
    prefs = await SharedPreferences.getInstance();
  }

  // Preferences Instance
  SharedPreferences prefs;

  // Favorites Videos
  List<Video> get favoriteVideos {
    var map = jsonDecode(prefs.getString('favoriteVideos') ?? "{}");
    List<Video> videos = [];
    if (map.isNotEmpty) {
      if (map['favoriteVideos'].isNotEmpty) {
        map['favoriteVideos'].forEach((v) {
          videos.add(Video.fromMap(v));
        });
      }
    }
    return videos;
  }
  set favoriteVideos(List<Video> videos) {
    var map = videos.map((e) {
      return e.toMap();
    }).toList();
    String json = jsonEncode({ 'favoriteVideos': map });
    prefs.setString('favoriteVideos', json).then((_) {
      notifyListeners();
    });
  }

  // Watch Later Videos
  List<Video> get watchLaterVideos {
    var map = jsonDecode(prefs.getString('watchLaterList') ?? "{}");
    List<Video> videos = [];
    if (map.isNotEmpty) {
      if (map['watchLaterList'].isNotEmpty) {
        map['watchLaterList'].forEach((v) {
          videos.add(Video.fromMap(v));
        });
      }
    }
    return videos;
  }
  set watchLaterVideos(List<Video> videos) {
    var map = videos.map((e) {
      return e.toMap();
    }).toList();
    String json = jsonEncode({ 'watchLaterList': map });
    prefs.setString('watchLaterList', json).then((_) {
      notifyListeners();
    });
  }

  // View History Videos
  List<Video> get viewHistory {
    var map = jsonDecode(prefs.getString('viewHistory') ?? "{}");
    List<Video> videos = [];
    if (map.isNotEmpty) {
      if (map['viewHistory'].isNotEmpty) {
        map['viewHistory'].forEach((v) {
          videos.add(Video.fromMap(v));
        });
      }
    }
    return videos;
  }
  set addVideoToViewHistory(Video video) {
    List<Video> videos = viewHistory;
    videos.add(video);
    var map = videos.map((e) {
      return e.toMap();
    }).toList();
    String json = jsonEncode({ 'viewHistory': map });
    prefs.setString('viewHistory', json).then((_) {
      notifyListeners();
    });
  }

  // Join Telegram Dialog
  bool get showJoinTelegramDialog {
    return prefs.getBool('joinTelegramDialog') ?? true;
  }
  set showJoinTelegramDialog(bool value) {
    prefs.setBool('joinTelegramDialog', value);
  }
  // Remind Later
  bool remindTelegramLater = false;

  // Enable/Disable App's BlurUI
  bool get enableBlurUI {
    return prefs.getBool('enable_BlurUI') ?? false;
  }
  set enableBlurUI(bool value) {
    prefs.setBool('enable_BlurUI', value);
    notifyListeners();
  }

  bool get enablePlayerBlurBackground {
    return prefs?.getBool('enablePlayerBlurBackground') ?? true;
  }
  set enablePlayerBlurBackground(bool value) {
    prefs.setBool('enablePlayerBlurBackground', value);
    notifyListeners();
  }

  // MusicPlayer Artwork Rounded Corners
  double get musicPlayerArtworkRoundCorners {
    return prefs.getDouble('musicPlayerArtworkRoundCorners') ?? 20;
  }
  set musicPlayerArtworkRoundCorners(double value) {
    prefs.setDouble('musicPlayerArtworkRoundCorners', value);
    notifyListeners();
  }

  // Youtube Auto-Play
  bool get youtubeAutoPlay {
    return prefs.getBool('youtubeAutoPlay') ?? true;
  }

  set youtubeAutoPlay(bool value) {
    prefs.setBool('youtubeAutoPlay', value);
    notifyListeners();
  }

  // Watch History
  List<Video> get watchHistory {
    String json = prefs.getString('watchHistory');
    if (json == null) return [];
    var map = jsonDecode(json);
    List<Video> history = [];
    if (map.isNotEmpty) {
      map.forEach((element) {
        history.add(Video.fromMap(element));
      });
    }
    return history;
  }

  set watchHistory(List<Video> history) {
    List<Map<String, dynamic>> map =
      history.map((e) => e.toMap()).toList();
    prefs.setString('watchHistory', jsonEncode(map));
    notifyListeners();
  }

  void watchHistoryInsert(dynamic video) {
    List<Video> history = watchHistory;
    history.add(video);
    watchHistory = history;
  }

}