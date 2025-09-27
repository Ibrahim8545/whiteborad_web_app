import 'package:flutter/material.dart';

enum GameServiceState { idle, playing, win, timeout, puzzleUpdate }

class GameService extends ChangeNotifier {
  GameServiceState _gameState = GameServiceState.idle;
  String _playerName = '';
  int _timeTaken = 0;
  List<int> _currentPuzzleOrder = [];

  // #region Getters
  GameServiceState get gameState => _gameState;
  String get playerName => _playerName;
  int get timeTaken => _timeTaken;
  List<int> get currentPuzzleOrder => _currentPuzzleOrder;
  // #endregion

  // --- دوال إرسال الأوامر من التابلت ---

  void startGame(String name, List<int> initialOrder) {
    // ⚠️ هنا يجب أن ترسل طلب (WebSocket/HTTP) لبدء اللعبة على شاشة العرض
    _playerName = name;
    _currentPuzzleOrder = initialOrder;

    // تحديث الحالة محلياً (للمحاكاة فقط - في الواقع، ستتلقى شاشة العرض هذا التحديث من اتصال خارجي)
    // startGame()
  }

  void updatePuzzle(List<int> newOrder) {
    // ⚠️ هنا يجب أن ترسل طلب (WebSocket) لتحديث ترتيب القطع على شاشة العرض
    // updatePuzzle()
  }

  void sendWin(String name, int time) {
    // ⚠️ هنا يجب أن ترسل طلب (WebSocket/HTTP) بانتهاء اللعبة بنجاح
    _playerName = name;
    _timeTaken = time;

    // تحديث الحالة محلياً (للمحاكاة فقط)
    // sendWin()
  }

  void sendTimeout(String name) {
    // ⚠️ هنا يجب أن ترسل طلب (WebSocket/HTTP) بانتهاء الوقت
    _playerName = name;

    // تحديث الحالة محلياً (للمحاكاة فقط)
    // sendTimeout()
  }

  // --- دوال استقبال الأوامر (التي يجب أن تعمل عند استقبال البيانات من الاتصال) ---

  // مثال: عند استقبال رسالة "game_start" من الاتصال الخارجي:
  void receiveGameStart(String name, List<int> initialOrder) {
    _playerName = name;
    _currentPuzzleOrder = initialOrder;
    _gameState = GameServiceState.playing;
    notifyListeners();
  }

  // مثال: عند استقبال رسالة "puzzle_update" من الاتصال الخارجي:
  void receivePuzzleUpdate(List<int> newOrder) {
    _currentPuzzleOrder = newOrder;
    _gameState = GameServiceState.puzzleUpdate;
    notifyListeners();
  }

  // مثال: عند استقبال رسالة "game_win" من الاتصال الخارجي:
  void receiveGameWin(String name, int time) {
    _playerName = name;
    _timeTaken = time;
    _gameState = GameServiceState.win;
    notifyListeners();
  }
}
