part of sni_state;

typedef PaginatedCallback<T> = FutureOr<List<T>> Function(int page, int limit);

class PaginatedStateOf<T> extends StateOf<List<T>> {
  int _page = 1;
  final int limit;
  final PaginatedCallback<T> onFetch;

  PaginatedStateOf(
    List<T> initialValue, {
    required this.onFetch,
    this.limit = 25,
  }) : super(initialValue);

  Future<void> firstPage() async {
    _page = 1;
    await update((prev) async {
      return await onFetch(
        _page,
        limit,
      );
    });
  }

  bool _isFetchNext = false;
  Future<void> nextPage() async {
    if (_isFetchNext) return;
    _isFetchNext = true;

    try {
      await update((previousValue) async {
        final list = await onFetch(_page + 1, limit);
        if (list.isNotEmpty) {
          _page++;
          previousValue.addAll(list);
        }

        return previousValue;
      });
    } finally {
      _isFetchNext = false;
    }
  }
}
