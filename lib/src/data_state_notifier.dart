part of sni_state;

typedef DataStateWidgetBuilder<T> = Widget Function(
  BuildContext context,
  T data,
);

typedef UpdateCallback<T> = FutureOr<T> Function(T previousValue);
typedef ChildUpdateCallback<T, X> = FutureOr<X> Function(
  T parentData,
  X previousValue,
);

class StateOf<T> {
  final StreamController<DataSnapshot<T>> _controller =
      StreamController.broadcast(
    sync: true,
  );

  late DataSnapshot<T> _data;
  DataSnapshot<T> get current => _data;

  bool _isReadOnly = false;

  StreamSubscription? _parentSubscription;
  StateOf<X> watch<X>(
    X initialValue, {
    required ChildUpdateCallback<T, X> onUpdate,
  }) {
    final child = StateOf<X>(initialValue);
    child._isReadOnly = true;
    child._parentSubscription = listen((data) async {
      final value = await onUpdate(data, child.value);
      child._updateValue(value);
    });

    onUpdate(value, initialValue);
    return child;
  }

  bool isDisposed = false;
  void dispose() {
    if (isDisposed) return;

    isDisposed = true;
    _parentSubscription?.cancel();
    _controller.close();
  }

  StateOf(T initialValue) {
    _data = DataSnapshot<T>(
      value: initialValue,
      isInProgress: false,
    );
    _controller.sink.add(_data);
  }

  void _updateValue(T value) {
    _data = DataSnapshot<T>(
      value: value,
      isInProgress: false,
    );

    _controller.sink.add(_data);
  }

  T get value => current.value;
  set value(T value) {
    assert(_isReadOnly == false);
    _updateValue(value);
  }

  bool get isInProgress => current.isInProgress;
  set isInProgress(bool isInProgress) {
    _data = DataSnapshot<T>(
      value: value,
      isInProgress: isInProgress,
    );

    _controller.sink.add(_data);
  }

  Future<void> update(
    UpdateCallback<T> callback, {
    bool withProgress = true,
  }) async {
    assert(_isReadOnly == false);

    dynamic error;
    try {
      if (withProgress) {
        _data = DataSnapshot<T>(
          value: _data.value,
          isInProgress: true,
        );

        if (isDisposed) return;
        _controller.sink.add(_data);
      }

      _data = DataSnapshot<T>(
        value: await callback(_data.value),
        isInProgress: false,
      );

      if (isDisposed) return;
      _controller.sink.add(_data);
    } on DioError catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code >= 500) {
        error = ServerException(e.error);
      } else if (code == 404) {
        error = NotFoundException(e.error);
      } else if (code == 401) {
        error = UnauthorizedException(e.error);
      } else {
        if (e.error is HttpException) {
          error = e.error;
        } else {
          error = HttpException(e.error);
        }
      }
    } catch (e) {
      error = e;
    } finally {
      if (!_controller.isClosed) {
        if (!isDisposed) {
          _data = DataSnapshot<T>(
            value: _data.value,
            isInProgress: false,
            error: error,
          );

          _controller.sink.add(_data);
        }
      }
    }
  }

  StreamSubscription<T> listen(
    void Function(T data) onData, {
    bool withProgress = false,
  }) {
    return transform<T>((data) {
      if (!withProgress && data.isInProgress) {
        return null;
      }

      return data.value;
    }).listen(onData);
  }

  Stream<DataSnapshot<T>> get stream => _controller.stream;
  Stream<E> _transform<E>(
    E? Function(DataSnapshot<T> data) convert,
  ) async* {
    var val = convert(current);
    if (val != null) {
      yield val;
    }

    await for (final data in stream) {
      val = convert(data);
      if (val != null) {
        yield val;
      }
    }
  }

  Stream<E> transform<E>(
    E? Function(DataSnapshot<T> data) convert,
  ) =>
      _transform(convert).asBroadcastStream();
}
