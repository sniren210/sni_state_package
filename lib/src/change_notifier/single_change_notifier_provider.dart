part of sni_state;

abstract class SingleChangeNotifierProvider<T> with ChangeNotifier {
  Object? _error;
  Object? get error => _error;
  bool get hasError => error != null;

  bool _isFetching = false;
  bool get isFetching => _isFetching;

  bool _isDisposed = false;
  SingleChangeNotifierProvider() {
    if (autoFetch) {
      fetchData();
      _isFetching = true;
    }
  }

  bool get autoFetch => true;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  late T _value;
  T get value => hasError ? throw _error! : _value;

  @protected
  Future<T> fetch();

  Future<void> fetchData() async {
    if (_isFetching) return;
    try {
      _error = null;
      _isFetching = true;

      notifyListeners();

      _value = await fetch();
    } catch (e) {
      _error = e;
    } finally {
      await Future.delayed(const Duration(milliseconds: 300)); // debounce
      _isFetching = false;
      notifyListeners();
    }
  }
}
