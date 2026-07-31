enum GameEngineState {
  unsupported,
  waitingForMemory,
  ready,
  readError,
}

class GameEngineStatus<TSnapshot> {
  final GameEngineState state;
  final String engineName;
  final String gameName;
  final int systemRamSize;
  final TSnapshot? snapshot;
  final String? message;

  const GameEngineStatus({
    required this.state,
    required this.engineName,
    required this.gameName,
    required this.systemRamSize,
    required this.snapshot,
    this.message,
  });

  bool get isReady => state == GameEngineState.ready && snapshot != null;
}
