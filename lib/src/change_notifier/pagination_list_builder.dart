part of sni_state;

class PaginationListBuilder<E, T extends ListChangeNotifierProvider<E>>
    extends StatelessWidget {
  /// Define your screen when your state is currently show error .
  final Widget Function(Object? error) errorBuilder;

  /// Allow you to custom your screen when your state is fetching data. This builder is redundant if you set [useProgressBuilder] to false .
  final WidgetBuilder? progressBuilder;

  /// Set this property to true if you want to custom your screen while state is fetching data
  final bool useProgressBuilder;

  /// Define your screen when your state is success fetching data .
  final Widget Function(BuildContext context, bool isLoading, List<E> value)
      builder;

  const PaginationListBuilder({
    Key? key,
    required this.errorBuilder,
    this.progressBuilder,
    this.useProgressBuilder = false,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final T provider = context.watch();

    if (provider.hasError) {
      return errorBuilder(provider.error);
    }

    if (provider.isFetching &&
        (useProgressBuilder && progressBuilder != null)) {
      return progressBuilder!(context);
    }

    final List<E> value = provider.isFetching ? [] : provider.value;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter == 0) {
          Future.delayed(
            const Duration(
              seconds: 1,
            ),
            () {
              context.read<T>().fetchMoreData();
            },
          );
        }
        return false;
      },
      child: builder(
        context,
        provider.isFetching || provider.isFetchingMore,
        value,
      ),
    );
  }
}
