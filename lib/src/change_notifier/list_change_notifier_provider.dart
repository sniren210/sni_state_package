part of sni_state;

abstract class ListChangeNotifierProvider<Type>
    extends SingleChangeNotifierProvider<List<Type>> {
  @protected
  int get limit => 25;

  int _page = 1;
  int get page => _page;

  bool _isInitialized = false;

  @override
  List<Type> get value => !_isInitialized || isFetching ? [] : super.value;

  @override
  Future<void> fetchData() async {
    try {
      _page = 1;
      await super.fetchData();
      _maybeHasMore = !hasError && super.value.length >= limit;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  bool _maybeHasMore = true;
  bool get maybeHasMore => _maybeHasMore;

  bool _isFetchingMore = false;
  bool get isFetchingMore => _isFetchingMore;
  Future<void> fetchMoreData() async {
    if (_isFetchingMore || isFetching) return;
    if (!_maybeHasMore) return;

    try {
      _isFetchingMore = true;
      notifyListeners();

      _page++;
      final newValue = await fetch();
      if (newValue.isNotEmpty) {
        value.addAll(newValue);
      } else {
        _page--;
      }

      _maybeHasMore = newValue.length >= limit;
    } finally {
      await Future.delayed(const Duration(milliseconds: 300)); // debounce
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  @override
  @protected
  Future<List<Type>> fetch() async {
    return fetchPage(_page, limit);
  }

  @protected
  Future<List<Type>> fetchPage(int page, int limit);
}
