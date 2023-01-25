part of sni_state;

mixin SearchNotifierProviderMixin<T> on SingleChangeNotifierProvider<T> {
  String _search = '';
  String get search => _search;

  set search(String val) {
    _search = val;
    fetchData();
  }
}
