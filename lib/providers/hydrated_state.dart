import 'dart:async';

typedef StateReader<T> = T Function();
typedef StateWriter<T> = void Function(T value);
typedef RestoreLoader<T> = Future<T> Function();
typedef PersistWriter<T> = Future<void> Function(T value);
typedef StateMutationApplier<T, M> = T Function(T state, M mutation);

class HydratedValueController<T> {
  HydratedValueController({
    required StateReader<T> readState,
    required StateWriter<T> writeState,
    required RestoreLoader<T> load,
    required PersistWriter<T> persist,
    required bool Function() isMounted,
    bool Function()? canApplyRestore,
  }) : _readState = readState,
       _writeState = writeState,
       _load = load,
       _persist = persist,
       _isMounted = isMounted,
       _canApplyRestore = canApplyRestore;

  final StateReader<T> _readState;
  final StateWriter<T> _writeState;
  final RestoreLoader<T> _load;
  final PersistWriter<T> _persist;
  final bool Function() _isMounted;
  final bool Function()? _canApplyRestore;

  bool _isHydrating = false;
  int _generation = 0;
  T? _pendingValue;
  Completer<void>? _hydrationCompleter;

  bool get isHydrating => _isHydrating;

  Future<void> get whenHydrated =>
      _hydrationCompleter?.future ?? Future<void>.value();

  void startRestore() {
    _isHydrating = true;
    _pendingValue = null;
    final generation = ++_generation;
    _hydrationCompleter = Completer<void>();
    unawaited(_restore(generation));
  }

  void cancelRestore() {
    _generation += 1;
    _isHydrating = false;
    _pendingValue = null;
    _completeHydration();
  }

  Future<void> setValue(T value, {bool waitForHydration = false}) async {
    _writeState(value);

    if (_isHydrating) {
      _pendingValue = value;
      if (waitForHydration) {
        await whenHydrated;
      }
      return;
    }

    await _persist(value);
    _pendingValue = null;
  }

  Future<void> _restore(int generation) async {
    try {
      final restoredValue = await _load();
      if (!_isMounted()) return;
      if (_generation != generation) return;
      final canApplyRestore = _canApplyRestore;
      if (canApplyRestore != null && !canApplyRestore()) return;

      final nextValue = _pendingValue ?? restoredValue;
      _isHydrating = false;
      _generation = 0;
      _pendingValue = null;

      if (_readState() != nextValue) {
        _writeState(nextValue);
      }

      await _persist(nextValue);
    } finally {
      if (_generation == generation) {
        _isHydrating = false;
        _pendingValue = null;
        _generation = 0;
      }
      _completeHydration();
    }
  }

  void _completeHydration() {
    final completer = _hydrationCompleter;
    _hydrationCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }
}

class HydratedMutationController<T, M> {
  HydratedMutationController({
    required StateReader<T> readState,
    required StateWriter<T> writeState,
    required RestoreLoader<T> load,
    required PersistWriter<T> persist,
    required StateMutationApplier<T, M> applyMutation,
    required bool Function() isMounted,
    bool Function()? canApplyRestore,
  }) : _readState = readState,
       _writeState = writeState,
       _load = load,
       _persist = persist,
       _applyMutation = applyMutation,
       _isMounted = isMounted,
       _canApplyRestore = canApplyRestore;

  final StateReader<T> _readState;
  final StateWriter<T> _writeState;
  final RestoreLoader<T> _load;
  final PersistWriter<T> _persist;
  final StateMutationApplier<T, M> _applyMutation;
  final bool Function() _isMounted;
  final bool Function()? _canApplyRestore;

  bool _isHydrating = false;
  int _generation = 0;
  List<M> _pendingMutations = <M>[];
  Completer<void>? _hydrationCompleter;

  bool get isHydrating => _isHydrating;

  Future<void> get whenHydrated =>
      _hydrationCompleter?.future ?? Future<void>.value();

  void startRestore() {
    _isHydrating = true;
    _pendingMutations = <M>[];
    final generation = ++_generation;
    _hydrationCompleter = Completer<void>();
    unawaited(_restore(generation));
  }

  void cancelRestore() {
    _generation += 1;
    _isHydrating = false;
    _pendingMutations = <M>[];
    _completeHydration();
  }

  Future<void> apply(M mutation) async {
    final nextState = _applyMutation(_readState(), mutation);
    _writeState(nextState);

    if (_isHydrating) {
      _pendingMutations = <M>[..._pendingMutations, mutation];
      return;
    }

    await _persist(nextState);
  }

  Future<void> _restore(int generation) async {
    try {
      final restoredState = await _load();
      if (!_isMounted()) return;
      if (_generation != generation) return;
      final canApplyRestore = _canApplyRestore;
      if (canApplyRestore != null && !canApplyRestore()) return;

      var nextState = restoredState;
      for (final mutation in _pendingMutations) {
        nextState = _applyMutation(nextState, mutation);
      }

      _isHydrating = false;
      _generation = 0;
      _pendingMutations = <M>[];
      _writeState(nextState);

      await _persist(nextState);
    } finally {
      if (_generation == generation) {
        _isHydrating = false;
        _pendingMutations = <M>[];
        _generation = 0;
      }
      _completeHydration();
    }
  }

  void _completeHydration() {
    final completer = _hydrationCompleter;
    _hydrationCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }
}
