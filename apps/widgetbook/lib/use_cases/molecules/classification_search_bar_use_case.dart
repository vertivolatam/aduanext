import 'package:aduanext_mobile/features/classifier/classification_dto.dart';
import 'package:aduanext_mobile/shared/ui/molecules/classification_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Default',
  type: ClassificationSearchBar,
  path: '[molecules]',
)
Widget buildClassificationSearchBarUseCase(BuildContext context) {
  return _InteractiveClassificationSearchBar(
    loading: context.knobs.boolean(
      label: 'Loading',
      initialValue: false,
    ),
  );
}

/// Wrapper con estado: controller propio y cambio de modo en vivo.
class _InteractiveClassificationSearchBar extends StatefulWidget {
  final bool loading;

  const _InteractiveClassificationSearchBar({required this.loading});

  @override
  State<_InteractiveClassificationSearchBar> createState() =>
      _InteractiveClassificationSearchBarState();
}

class _InteractiveClassificationSearchBarState
    extends State<_InteractiveClassificationSearchBar> {
  final _controller = TextEditingController(text: 'laptop 14 pulgadas');
  ClassificationSearchMode _mode = ClassificationSearchMode.values.first;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClassificationSearchBar(
      controller: _controller,
      mode: _mode,
      onModeChanged: (mode) => setState(() => _mode = mode),
      onSubmit: () {},
      loading: widget.loading,
    );
  }
}
