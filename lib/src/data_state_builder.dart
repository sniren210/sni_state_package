part of sni_state;

typedef StateOfBuilderFunction<T> = Widget Function(
  BuildContext context,
  DataSnapshot<T> snapshot,
);

class StateOfBuilder<T> extends StatelessWidget {
  final StateOf<T> state;
  final StateOfBuilderFunction<T> builder;

  const StateOfBuilder({
    Key? key,
    required this.state,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DataSnapshot<T>>(
      stream: state.stream,
      initialData: state.current,
      builder: (context, snapshot) {
        return builder(context, snapshot.data!);
      },
    );
  }
}
