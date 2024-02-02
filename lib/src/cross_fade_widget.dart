import 'package:cross_fade/src/widget_transition.dart';
import 'package:flutter/material.dart';

import 'widgets/animated_size.dart';
import 'widgets/clip_rect.dart';

/// A widget to apply a crossfade animation
/// between different states and/or widgets.
class CrossFade<T> extends StatelessWidget {
  /// The current value.
  final T value;

  /// The builder which builds the different values during the animation.
  final Widget Function(BuildContext, T) builder;

  /// The duration of the fading.
  final Duration duration;

  /// The overriding of the equals function.
  /// [CrossFade] only animates between two different values
  /// if [equals] returns [false] for these two.
  final bool Function(T, T) equals;

  /// [CrossFade] only highlights the new value during the animation
  /// if [highlightTransition] returns [true].
  final bool Function(T, T) highlightTransition;

  /// The maximum scale during the highlight animation.
  final double highlightScale;

  /// The duration of the whole highlight animation. Defaults to [duration].
  final Duration? highlightDuration;

  /// The alignment for the children of the underlying stack.
  final AlignmentGeometry stackAlignment;

  /// The clip behaviour for clipping while the size animation.
  /// For more customization like BorderRadius or similar please use
  /// widgets like [ClipRRect] or [Container] and their [clipBehavior].
  final Clip clipBehavior;

  /// Curve of the fading in animation.
  final Curve curve;

  /// Curve of the fading out animation. Defaults to [curve.flipped].
  final Curve? disappearingCurve;

  /// Curve of the highlighting animation.
  final Curve highlightingCurve;

  /// Reverse curve of the highlighting animation.
  /// Defaults to [highlightingCurve.flipped].
  final Curve? highlightingReverseCurve;

  /// Curve of the size animation.
  ///
  /// If you want to disable the size animation for performance reasons,
  /// set [sizeDuration] to [Duration.zero].
  final Curve sizeCurve;

  /// Duration of the size animation. Defaults to [duration].
  ///
  /// If you want to disable the size animation for performance reasons,
  /// set [sizeDuration] to [Duration.zero].
  final Duration? sizeDuration;

  // const constructor doesn't make sense here
  /// The default constructor of [CrossFade].
  ///
  /// If you want to disable the size animation for performance reasons,
  /// set [sizeDuration] to [Duration.zero].
  const CrossFade({
    Key? key,
    this.duration = const Duration(milliseconds: 750),
    required this.value,
    required this.builder,
    this.equals = _defaultEquals,
    this.highlightTransition = _defaultHighlightTransition,
    this.stackAlignment = AlignmentDirectional.center,
    this.highlightScale = 1.2,
    this.highlightDuration,
    this.clipBehavior = Clip.none,
    this.curve = Curves.easeIn,
    this.disappearingCurve,
    this.highlightingCurve = Curves.ease,
    this.highlightingReverseCurve,
    this.sizeCurve = Curves.linear,
    this.sizeDuration,
  }) : super(key: key);

  static bool _defaultEquals(dynamic t1, dynamic t2) => t1 == t2;

  static bool _defaultHighlightTransition(dynamic t1, dynamic t2) => false;

  @override
  Widget build(BuildContext context) {
    return WidgetTransition<T>(
        value: value,
        builder: builder,
        duration: duration,
        equals: equals,
        highlightTransition: highlightTransition,
        highlightScale: highlightScale,
        highlightDuration: highlightDuration,
        curve: curve,
        disappearingCurve: disappearingCurve,
        highlightingCurve: highlightingCurve,
        highlightingReverseCurve: highlightingReverseCurve,
        transitionBuilder:
            (context, previousChild, child, previous, current, animation) {
          return LayoutBuilder(
            builder: (context, constraints) => Stack(
              fit: StackFit.passthrough,
              alignment: stackAlignment,
              children: [
                if (previousChild != null)
                  Positioned.fill(
                    child: CustomClipRect(
                      clipBehavior: clipBehavior,
                      child: OverflowBox(
                        alignment: stackAlignment,
                        minWidth: constraints.minWidth,
                        maxWidth: constraints.maxWidth,
                        minHeight: constraints.minHeight,
                        maxHeight: constraints.maxHeight,
                        child: ConstrainedBox(
                          constraints: constraints,
                          child: AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) => Opacity(
                              opacity: 1 - animation.value,
                              child: child,
                            ),
                            child: previousChild,
                          ),
                        ),
                      ),
                    ),
                  ),
                CustomAnimatedSize(
                  key: const ValueKey(0),
                  clipBehavior: clipBehavior,
                  duration: sizeDuration ?? duration,
                  curve: sizeCurve,
                  alignment: stackAlignment,
                  child: AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) => Opacity(
                      opacity: animation.value,
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }
}
