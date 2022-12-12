import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tictactoe/customdialog.dart';
import 'package:tictactoe/gamebutton.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<GameButton> buttonsList = [];
  var player1 = [];
  var player2 = [];
  var activePlayer = {};
  var playerConfig = [];
  String lastWinner = "";
  String _connectionStatus = 'Unknown'; //connectivity status
  bool _online = true; //connectivity online or offline
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    buttonsList = doInit();
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    ConnectivityResult result = await _connectivity.checkConnectivity();
    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
        setState(() {
          _connectionStatus = 'Online';
          _online = true;
        });
        break;
      case ConnectivityResult.none:
        setState(() {
          _connectionStatus = 'Offline';
          _online = false;
        });
        break;
      default:
        setState(() => _connectionStatus = 'Failed to get connectivity.');
        break;
    }
  }

  List<GameButton> doInit() {
    playerConfig = [
      {
        'number': 1,
        'text': 'X',
        'color': Colors.green,
        'cells': [],
        'human': true
      },
      {
        'number': 2,
        'text': '0',
        'color': Colors.red,
        'cells': [],
        'human': false
      }
    ];
    activePlayer = playerConfig[0];

    var gameButtons = <GameButton>[
      GameButton(id: 1),
      GameButton(id: 2),
      GameButton(id: 3),
      GameButton(id: 4),
      GameButton(id: 5),
      GameButton(id: 6),
      GameButton(id: 7),
      GameButton(id: 8),
      GameButton(id: 9),
    ];
    return gameButtons;
  }

  void changePlayer() {
    if (activePlayer == playerConfig[0]) {
      activePlayer = playerConfig[1];
    } else {
      activePlayer = playerConfig[0];
    }
  }

  void playGame(GameButton gb) {
    setState(() {
      gb.play(activePlayer['text'], activePlayer['color']);

      final List cells = activePlayer['cells'];
      cells.add(gb.id);

      int winner = checkWinner();
      if (winner != -1) {
        winnerDialog(winner);
        return;
      }

      changePlayer();

      if (!activePlayer['human']) {
        autoPlay();
      }
    });
  }

  void autoPlay() {
    var emptyCells = [];
    var list = List.generate(9, (i) => i + 1);
    for (var cellID in list) {
      if (!(playerConfig[0]['cells'].contains(cellID) ||
          playerConfig[1]['cells'].contains(cellID))) {
        emptyCells.add(cellID);
      }
    }

    var r = Random();
    var randIndex = r.nextInt(emptyCells.length - 1);
    var cellID = emptyCells[randIndex];
    int i = buttonsList.indexWhere((p) => p.id == cellID);
    playGame(buttonsList[i]);
  }

  int checkWinner() {
    var winner = -1;

    if (checkWinnerPlayer(playerConfig[0])) {
      winner = 1;
    } else if (checkWinnerPlayer(playerConfig[1])) {
      winner = 2;
    } else if (getMoves() == 9) {
      winner = 0;
    }

    return winner;
  }

  bool checkWinnerPlayer(dynamic player) {
    final List cells = player['cells'];

    return checkValidWin(cells, 1, 2, 3) || // Row 1
        checkValidWin(cells, 4, 5, 6) || // Row 2
        checkValidWin(cells, 7, 8, 9) || // Row 3
        checkValidWin(cells, 1, 4, 7) || // Column 1
        checkValidWin(cells, 2, 5, 8) || // Column 2
        checkValidWin(cells, 3, 6, 9) || // Column 3
        checkValidWin(cells, 1, 5, 9) || // Diagonal 1
        checkValidWin(cells, 3, 5, 7); // Diagonal 2
  }

  bool checkValidWin(List cells, int cell1, int cell2, int cell3) {
    return Set.from(cells).containsAll({cell1, cell2, cell3});
  }

  int getMoves() {
    return playerConfig[0]['cells'].length + playerConfig[1]['cells'].length;
  }

  void winnerDialog(int winner) {
    if (winner > 0) {
      saveLastWinner(winner, playerConfig);
      showDialog(
          context: context,
          builder: (_) => CustomDialog(
              title: "Player $winner Won",
              content: "Do you want to start a new game?",
              callback: newGame));
    } else if (winner == 0) {
      showDialog(
          context: context,
          builder: (_) => CustomDialog(
              title: "Game Tied",
              content: "Do you want to start a new game?",
              callback: newGame));
    }
  }

  void newGame() {
    if (Navigator.canPop(context)) Navigator.pop(context);
    setState(() {
      buttonsList = doInit();
    });
  }

  void loadLastWinner() async {
    if (lastWinner == "") {
      _showToast('There are not winners yet');
      return;
    }

    late int winner;

    if (_online) {
      var winnerData = await loadGameOnline(lastWinner);
      winner = int.parse(winnerData['winner']);
    } else {
      winner = await loadGameOffline();
    }

    _showToast('Last Winner was Player $winner');
  }

  void saveLastWinner(int winner, dynamic playerConfig) async {
    if (_online) {
      lastWinner = await saveGameOnline(winner, playerConfig);
    } else {
      await saveGameOffline(winner);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic Tac Toe'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 5.0,
                  mainAxisSpacing: 5.0),
              itemCount: buttonsList.length,
              itemBuilder: (context, i) => SizedBox(
                width: 5.0,
                height: 5.0,
                child: ElevatedButton(
                  onPressed: buttonsList[i].enabled
                      ? () => playGame(buttonsList[i])
                      : null,
                  child: Text(
                    buttonsList[i].text,
                    style: const TextStyle(color: Colors.white, fontSize: 20.0),
                  ),
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.resolveWith<Color>((states) {
                      return buttonsList[i].color;
                    }),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: newGame,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  child: const Text('New Game'),
                ),
                ElevatedButton(
                  onPressed: loadLastWinner,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  child: const Text('Last Winner'),
                ),
                Text(
                  _connectionStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _online ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

Future<String> saveGameOnline(int winner, dynamic game) async {
  final response = await http.post(
      Uri.https(
        'mes-ams-tictactoe-default-rtdb.europe-west1.firebasedatabase.app',
        'lastWinner.json',
      ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: convert.jsonEncode(<String, String>{
        'winner': winner.toString(),
        'player1': game[0]['cells'].toString(),
        'player2': game[1]['cells'].toString(),
      }));
  if (response.statusCode == 200) {
    var result = convert.jsonDecode(response.body);
    var resultId = result['name'];

    _showToast('Saved ID: $resultId');

    return resultId;
  } else {
    throw Exception('Failed to create user.');
  }
}

Future<dynamic> loadGameOnline(String id) async {
  final response = await http.get(
    Uri.https(
      'mes-ams-tictactoe-default-rtdb.europe-west1.firebasedatabase.app',
      'lastWinner.json',
    ),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );
  if (response.statusCode == 200) {
    var result = convert.jsonDecode(response.body);
    var winnerData = result[id];

    return winnerData;
  } else {
    throw Exception('Failed to create user.');
  }
}

Future<void> saveGameOffline(int winner) async {
  var box = await Hive.openBox('lastWinner');
  box.put('winner', winner);
}

Future<int> loadGameOffline() async {
  var box = await Hive.openBox('lastWinner');
  return box.get('winner');
}

void _showToast(message) =>
    Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_SHORT);
