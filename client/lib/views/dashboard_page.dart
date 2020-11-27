import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:client/utils/time.dart';
import 'package:client/widgets/sized_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:spotify_sdk/models/connection_status.dart';
import 'package:spotify_sdk/models/crossfade_state.dart';
import 'package:spotify_sdk/models/image_uri.dart';
import 'package:spotify_sdk/models/player_context.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class DashboardPage extends StatefulWidget {
  DashboardPage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final Logger _logger = Logger();
  bool _connected = false;
  bool _loading = false;
  int _counter = 0;
  String _timeString;

  CrossfadeState crossfadeState;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  void initState() {
    _timeString = _formatDateTime(DateTime.now());
    Timer.periodic(Duration(seconds: 1), (Timer t) => _getTime());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<ConnectionStatus>(
        stream: SpotifySdk.subscribeConnectionStatus(),
        builder: (context, snapshot) {
          _connected = false;
          print('CONNECTED 0??? ${snapshot}');
          if (snapshot.data != null) {
            print('CONNECTED 1??? ${json.encode(snapshot.data)}');
            _connected = snapshot.data.connected ?? true;
            print('CONNECTED 2??? ${_connected}');
          }
          return Scaffold(
            appBar: AppBar(
              title: const Text('SpotifySdk Example'),
              actions: [
                _connected
                    ? FlatButton(
                        child: const Text('Disconnect'), onPressed: disconnect)
                    : Container(child: Text('Not connected'))
              ],
            ),
            body: _sampleFlowWidget(context),
          );
        },
      ),
    );
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = _formatDateTime(now);
    setState(() {
      _timeString = formattedDateTime;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('Hms').format(dateTime);
  }

  Widget _sampleFlowWidget(BuildContext context2) {
    return Stack(
      children: [
        if (_timeString != null) Text(_timeString),
        ListView(
          padding: const EdgeInsets.all(8),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FlatButton(
                  child: const Icon(Icons.settings_remote),
                  onPressed: connectToSpotifyRemote,
                ),
                FlatButton(
                  child: const Text('get auth token '),
                  onPressed: getAuthenticationToken,
                ),
              ],
            ),
            const Divider(),
            const Text('Player State', style: TextStyle(fontSize: 16)),
            _connected
                ? playerStateWidget()
                : const Center(
                    child: Text('Not connected'),
                  ),
            const Divider(),
            const Text('Player Context', style: TextStyle(fontSize: 16)),
            _connected
                ? playerContextWidget()
                : const Center(
                    child: Text('Not connected'),
                  ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                SizedIconButton(
                  width: 50,
                  icon: Icons.skip_previous,
                  onPressed: skipPrevious,
                ),
                SizedIconButton(
                  width: 50,
                  icon: Icons.play_arrow,
                  onPressed: resume,
                ),
                SizedIconButton(
                  width: 50,
                  icon: Icons.pause,
                  onPressed: pause,
                ),
                SizedIconButton(
                  width: 50,
                  icon: Icons.skip_next,
                  onPressed: skipNext,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                SizedIconButton(
                  width: 50,
                  icon: Icons.queue_music,
                  onPressed: queue,
                ),
                SizedIconButton(
                  width: 50,
                  icon: Icons.play_circle_filled,
                  onPressed: play,
                ),
                SizedIconButton(
                  width: 50,
                  icon: Icons.repeat,
                  onPressed: toggleRepeat,
                ),
                SizedIconButton(
                  width: 50,
                  icon: Icons.shuffle,
                  onPressed: toggleShuffle,
                ),
              ],
            ),
            FlatButton(
                child: const Icon(Icons.favorite), onPressed: addToLibrary),
            Row(
              children: <Widget>[
                FlatButton(child: const Text('seek to'), onPressed: seekTo),
                FlatButton(
                    child: const Text('seek to relative'),
                    onPressed: seekToRelative),
              ],
            ),
            const Divider(),
            const Text(
              'Crossfade State',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            FlatButton(
                child: const Text('getCrossfadeState'),
                onPressed: getCrossfadeState),
            // ignore: prefer_single_quotes
            Text("Is enabled: ${crossfadeState?.isEnabled}"),
            // ignore: prefer_single_quotes
            Text("Duration: ${crossfadeState?.duration}"),
            const Divider(),
            _connected
                ? spotifyImageWidget()
                : const Text('Connect to see an image...'),
          ],
        ),
        _loading
            ? Container(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()))
            : const SizedBox(),
      ],
    );
  }

  Widget playerStateWidget() {
    return StreamBuilder<PlayerState>(
      stream: SpotifySdk.subscribePlayerState(),
      initialData: PlayerState(
        null,
        1,
        1,
        null,
        null,
        isPaused: false,
      ),
      builder: (BuildContext context, AsyncSnapshot<PlayerState> snapshot) {
        if (snapshot.data != null && snapshot.data.track != null) {
          var playerState = snapshot.data;
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('''
                    ${playerState.track.name}
                    by ${playerState.track.artist.name}
                    from the album ${playerState.track.album.name} '''),
              Text('Speed: ${playerState.playbackSpeed}'),
              Text(
                  'Progress: ${playerState.playbackPosition}ms/${playerState.track.duration}ms'),
              Text('IsPaused: ${playerState.isPaused}'),
              Text('Is Shuffling: ${playerState.playbackOptions.isShuffling}'),
              Text('RepeatMode: ${playerState.playbackOptions.repeatMode}'),
              Text('Image URI: ${playerState.track.imageUri.raw}'),
              Text('''
                  Is episode? ${playerState.track.isEpisode}. 
                  Is podcast?: ${playerState.track.isPodcast}'''),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text(
                    'Set Shuffle and Repeat',
                    style: TextStyle(fontSize: 16),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Repeat Mode:',
                      ),
                      DropdownButton<RepeatMode>(
                        value: RepeatMode.values[
                            playerState.playbackOptions.repeatMode.index],
                        items: [
                          DropdownMenuItem(
                            value: RepeatMode.off,
                            child: Text('off'),
                          ),
                          DropdownMenuItem(
                            value: RepeatMode.track,
                            child: Text('track'),
                          ),
                          DropdownMenuItem(
                            value: RepeatMode.context,
                            child: Text('context'),
                          ),
                        ],
                        onChanged: setRepeatMode,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Set shuffle: '),
                      Switch.adaptive(
                        value: playerState.playbackOptions.isShuffling,
                        onChanged: (bool shuffle) => setShuffle(
                          shuffle: shuffle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        } else {
          return const Center(
            child: Text('Not connected'),
          );
        }
      },
    );
  }

  Widget playerContextWidget() {
    return StreamBuilder<PlayerContext>(
      stream: SpotifySdk.subscribePlayerContext(),
      initialData: PlayerContext('', '', '', ''),
      builder: (BuildContext context, AsyncSnapshot<PlayerContext> snapshot) {
        if (snapshot.data != null && snapshot.data.uri != '') {
          var playerContext = snapshot.data;
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Title: ${playerContext.title}'),
              Text('Subtitle: ${playerContext.subtitle}'),
              Text('Type: ${playerContext.type}'),
              Text('Uri: ${playerContext.uri}'),
            ],
          );
        } else {
          return const Center(
            child: Text('Not connected'),
          );
        }
      },
    );
  }

  Widget spotifyImageWidget() {
    return FutureBuilder(
        future: SpotifySdk.getImage(
          imageUri: ImageUri(
              'spotify:image:ab67616d0000b2736b4f6358fbf795b568e7952d'),
          dimension: ImageDimension.large,
        ),
        builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
          if (snapshot.hasData) {
            return Image.memory(snapshot.data);
          } else if (snapshot.hasError) {
            setStatus(snapshot.error.toString());
            return SizedBox(
              width: ImageDimension.large.value.toDouble(),
              height: ImageDimension.large.value.toDouble(),
              child: const Center(child: Text('Error getting image')),
            );
          } else {
            return SizedBox(
              width: ImageDimension.large.value.toDouble(),
              height: ImageDimension.large.value.toDouble(),
              child: const Center(child: Text('Getting image...')),
            );
          }
        });
  }

  Future<void> disconnect() async {
    try {
      setState(() {
        _loading = true;
      });
      var result = await SpotifySdk.disconnect();
      setStatus(result ? 'disconnect successful' : 'disconnect failed');
      setState(() {
        _loading = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _loading = false;
      });
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setState(() {
        _loading = false;
      });
      setStatus('not implemented');
    }
  }

  Future<void> connectToSpotifyRemote() async {
    try {
      setState(() {
        _loading = true;
      });
      var result = await SpotifySdk.connectToSpotifyRemote(
          clientId: DotEnv().env['CLIENT_ID'].toString(),
          redirectUrl: DotEnv().env['REDIRECT_URI'].toString());
      setStatus(result
          ? 'connect to spotify successful'
          : 'connect to spotify failed');
      setState(() {
        _loading = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _loading = false;
      });
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setState(() {
        _loading = false;
      });
      setStatus('not implemented');
    }
  }

  Future<String> getAuthenticationToken() async {
    try {
      var authenticationToken = await SpotifySdk.getAuthenticationToken(
          clientId: DotEnv().env['CLIENT_ID'].toString(),
          redirectUrl: DotEnv().env['REDIRECT_URI'].toString(),
          scope: 'app-remote-control, '
              'user-modify-playback-state, '
              'playlist-read-private, '
              'playlist-modify-public,user-read-currently-playing');
      setStatus('Got a token: $authenticationToken');
      return authenticationToken;
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
      return Future.error('PlatformException!!! $e.code: $e.message');
    } on MissingPluginException {
      setStatus('not implemented');
      return Future.error('MissingPluginException!!! not implemented');
    }
  }

  Future getPlayerState() async {
    try {
      return await SpotifySdk.getPlayerState();
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future getCrossfadeState() async {
    try {
      var crossfadeStateValue = await SpotifySdk.getCrossFadeState();
      setState(() {
        crossfadeState = crossfadeStateValue;
      });
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> queue() async {
    try {
      await SpotifySdk.queue(
          spotifyUri: 'spotify:track:58kNJana4w5BIjlZE2wq5m');
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> toggleRepeat() async {
    try {
      await SpotifySdk.toggleRepeat();
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> setRepeatMode(RepeatMode repeatMode) async {
    try {
      await SpotifySdk.setRepeatMode(
        repeatMode: repeatMode,
      );
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> setShuffle({bool shuffle}) async {
    try {
      await SpotifySdk.setShuffle(
        shuffle: shuffle,
      );
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> toggleShuffle() async {
    try {
      await SpotifySdk.toggleShuffle();
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> play() async {
    try {
      await SpotifySdk.play(spotifyUri: 'spotify:track:58kNJana4w5BIjlZE2wq5m');
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> pause() async {
    try {
      await SpotifySdk.pause();
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> resume() async {
    try {
      await SpotifySdk.resume();
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> skipNext() async {
    try {
      await SpotifySdk.skipNext();
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> skipPrevious() async {
    try {
      await SpotifySdk.skipPrevious();
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> seekTo() async {
    try {
      await SpotifySdk.seekTo(positionedMilliseconds: 20000);
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> seekToRelative() async {
    try {
      await SpotifySdk.seekToRelativePosition(relativeMilliseconds: 20000);
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> addToLibrary() async {
    try {
      await SpotifySdk.addToLibrary(
          spotifyUri: 'spotify:track:58kNJana4w5BIjlZE2wq5m');
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  void setStatus(String code, {String message = ''}) {
    var text = message.isEmpty ? '' : ' : $message';
    _logger.d('$code$text');
  }
}
