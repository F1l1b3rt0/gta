import 'package:flutter/material.dart';
import 'package:gta/viewmodels/base_viewmodel.dart';

/// =======================================================
/// VIEWMODEL BUILDER
/// Widget que crea, provee y reconstruye con su ViewModel
/// =======================================================
class ViewModelBuilder<T extends BaseViewModel> extends StatefulWidget {
  final T Function() viewModelBuilder;
  final Widget Function(BuildContext context, T viewModel) builder;
  final bool disposeViewModel;

  const ViewModelBuilder({
    super.key,
    required this.viewModelBuilder,
    required this.builder,
    this.disposeViewModel = true,
  });

  @override
  State<ViewModelBuilder<T>> createState() => _ViewModelBuilderState<T>();
}

class _ViewModelBuilderState<T extends BaseViewModel>
    extends State<ViewModelBuilder<T>> {
  late T _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModelBuilder();
  }

  @override
  void dispose() {
    if (widget.disposeViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>.value(
      value: _viewModel,
      child: Consumer<T>(
        builder: (context, viewModel) {
          return widget.builder(context, viewModel);
        },
      ),
    );
  }
}

/// =======================================================
/// CHANGE NOTIFIER PROVIDER
/// Provider personalizado estilo simple
/// =======================================================
class ChangeNotifierProvider<T extends ChangeNotifier>
    extends StatefulWidget {
  final T Function()? create;
  final T? value;
  final Widget child;
  final bool disposeValue;

  const ChangeNotifierProvider({
    super.key,
    required T Function() create,
    required this.child,
    this.disposeValue = true,
  }) : create = create,
       value = null;

  const ChangeNotifierProvider.value({
    super.key,
    required T value,
    required this.child,
    this.disposeValue = false,
  }) : create = null,
       value = value;

  @override
  State<ChangeNotifierProvider<T>> createState() =>
      _ChangeNotifierProviderState<T>();
}

class _ChangeNotifierProviderState<T extends ChangeNotifier>
    extends State<ChangeNotifierProvider<T>> {
  late T _notifier;

  @override
  void initState() {
    super.initState();

    if (widget.value != null) {
      _notifier = widget.value!;
    } else {
      _notifier = widget.create!();
    }
  }

  @override
  void dispose() {
    if (widget.disposeValue) {
      _notifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedNotifierProvider<T>(
      notifier: _notifier,
      child: widget.child,
    );
  }
}

/// =======================================================
/// INHERITED PROVIDER
/// =======================================================
class _InheritedNotifierProvider<T extends ChangeNotifier>
    extends InheritedNotifier<T> {
  const _InheritedNotifierProvider({
    super.key,
    required super.notifier,
    required super.child,
  });

  static T of<T extends ChangeNotifier>(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<
            _InheritedNotifierProvider<T>>();

    if (widget == null || widget.notifier == null) {
      throw FlutterError(
        'No se encontró ChangeNotifierProvider<$T> en el árbol.',
      );
    }

    return widget.notifier!;
  }
}

/// =======================================================
/// CONSUMER
/// =======================================================
class Consumer<T extends ChangeNotifier> extends StatelessWidget {
  final Widget Function(BuildContext context, T value) builder;

  const Consumer({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = _InheritedNotifierProvider.of<T>(context);

    return AnimatedBuilder(
      animation: notifier,
      builder: (context, _) {
        return builder(context, notifier);
      },
    );
  }
}

/// =======================================================
/// EXTENSION OPCIONAL
/// context.read<T>()
/// =======================================================
extension ProviderExtension on BuildContext {
  T read<T extends ChangeNotifier>() {
    return _InheritedNotifierProvider.of<T>(this);
  }
}