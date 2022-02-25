import 'package:flutter/material.dart';

class CrossFade<T> extends StatefulWidget {
  ///The current value
  final T value;

  ///The builder which builds the different values during the animation.
  final Widget Function(BuildContext, T) builder;

  ///The duration of the fading.
  final Duration duration;

  ///The overriding of the equals function.
  ///[CrossFade] only animates between two different values
  ///if [equals] returns [false] for these two.
  final bool Function(T, T) equals;

  ///[CrossFade] only highlights the new value during the animation
  ///if [highlightTransition] returns [true].
  final bool Function(T, T) highlightTransition;

  ///The maximum scale during the highlight animation.
  final double highlightScale;

  ///The duration of the highlight animation.
  final Duration highlightDuration;

  ///The alignment for the children of the underlying stack.
  final AlignmentGeometry stackAlignment;

  ///The default constructor of [CrossFade]
  const CrossFade({
    Key? key,
    this.duration = const Duration(milliseconds: 750),
    required this.value,
    required this.builder,
    this.equals = _defaultEquals,
    this.highlightTransition = _defaultHighlightTransition,
    this.stackAlignment = AlignmentDirectional.center,
    this.highlightScale = 1.2,
    this.highlightDuration = const Duration(milliseconds: 750),
  }) : super(key: key);

  static bool _defaultEquals(dynamic t1, dynamic t2) => t1 == t2;

  static bool _defaultHighlightTransition(dynamic t1, dynamic t2) => false;

  @override
  _CrossFadeState<T> createState() => _CrossFadeState<T>();
}

class _CrossFadeState<T> extends State<CrossFade<T>>
    with TickerProviderStateMixin {
  late final List<T> _todo;
  late final AnimationController _opacityController;
  late final AnimationController _sizeController;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _sizeAnimation;
  final UniqueKey _stateKey = UniqueKey();
  final UniqueKey _animatedSizeKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _todo = [widget.value];
    _opacityController =
        AnimationController(vsync: this, duration: widget.duration, value: 1.0)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              if (_todo.length <= 1) return;
              _todo.removeAt(0);
              if (_todo.length > 1) {
                _animateNext();
              }
            }
          });

    _sizeController =
        AnimationController(vsync: this, duration: widget.highlightDuration);

    _opacityAnimation = CurvedAnimation(
      parent: _opacityController,
      curve: Curves.easeIn,
    );

    _sizeAnimation = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(0.0),
          weight: 25.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.ease)),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.ease.flipped)),
          weight: 50.0,
        ),
      ],
    ).animate(_sizeController);
  }

  @override
  void dispose() {
    _opacityController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CrossFade<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.equals(oldWidget.value, widget.value)) {
      if (_todo.length < 3) {
        _todo.add(widget.value);
      } else {
        _todo[_todo.length - 1] = widget.value;
      }
      if (!_opacityController.isAnimating) {
        _animateNext();
      }
    }
    if (oldWidget.duration != widget.duration) {
      _opacityController.duration = widget.duration;
    }
    if (oldWidget.highlightDuration != widget.highlightDuration) {
      _sizeController.duration = widget.highlightDuration;
    }
  }

  void _animateNext() {
    if (_todo.length < 2) return;
    if (widget.highlightTransition.call(_todo[0], _todo[1])) {
      _sizeController.forward(from: 0.0);
    }
    _opacityController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    T current = _todo.length > 1 ? _todo[1] : _todo[0];
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.passthrough,
        alignment: widget.stackAlignment,
        children: [
          if (_todo.length > 1)
            Positioned.fill(
              child: OverflowBox(
                alignment: widget.stackAlignment,
                minWidth: constraints.minWidth,
                maxWidth: constraints.maxWidth,
                minHeight: constraints.minHeight,
                maxHeight: constraints.maxHeight,
                child: AnimatedBuilder(
                  animation: _opacityAnimation,
                  builder: (context, child) => Opacity(
                    key: getKey(_todo[0]),
                    opacity: 1 - _opacityAnimation.value,
                    child: child,
                  ),
                  child: widget.builder(context, _todo[0]),
                ),
              ),
            ),
          AnimatedBuilder(
            key: _animatedSizeKey,
            animation: _sizeAnimation,
            builder: (context, child) => Transform.scale(
              scale: 1.0 + (widget.highlightScale - 1.0) * _sizeAnimation.value,
              child: child,
            ),
            child: AnimatedSize(
              clipBehavior: Clip.none,
              duration: widget.duration,
              child: AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) => Opacity(
                  key: getKey(current),
                  opacity: _opacityAnimation.value,
                  child: child,
                ),
                child: widget.builder(context, current),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _LocalKey<T> getKey(T value) => _LocalKey(_stateKey, value);
}

class _LocalKey<T> extends LocalKey {
  final Key stateKey;
  final T value;

  const _LocalKey(this.stateKey, this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _LocalKey &&
          runtimeType == other.runtimeType &&
          stateKey == other.stateKey &&
          value == other.value;

  @override
  int get hashCode => stateKey.hashCode ^ value.hashCode;
}
