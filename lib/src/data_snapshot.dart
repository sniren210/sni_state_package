part of sni_state;

class DataSnapshot<T> {
  final T value;
  final bool isInProgress;
  final dynamic error;
  bool get hasError => error != null;

  const DataSnapshot({
    required this.value,
    required this.isInProgress,
    this.error,
  });
}
