import 'package:flutter/material.dart';

/// [CustomScrollView] — guruh sarlavhasi kontent bilan birga yuqoriga suriladi.
class GapGroupScrollBody extends StatelessWidget {
  const GapGroupScrollBody({
    super.key,
    required this.header,
    required this.padding,
    required this.children,
    this.controller,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
  });

  final Widget header;
  final EdgeInsetsGeometry padding;
  final List<Widget> children;
  final ScrollController? controller;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      keyboardDismissBehavior: keyboardDismissBehavior,
      slivers: [
        SliverToBoxAdapter(child: header),
        SliverPadding(
          padding: padding,
          sliver: SliverList(
            delegate: SliverChildListDelegate(children),
          ),
        ),
      ],
    );
  }
}

/// Qisqa matn/markaz: sarlavha surilganda pastki qism to‘ldiriladi.
class GapGroupScrollBodyFill extends StatelessWidget {
  const GapGroupScrollBodyFill({
    super.key,
    required this.header,
    required this.padding,
    required this.child,
  });

  final Widget header;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: header),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ],
    );
  }
}
