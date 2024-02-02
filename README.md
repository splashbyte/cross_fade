<a href="https://pub.dev/packages/cross_fade"><img src="https://img.shields.io/pub/v/cross_fade.svg?style=flat?logo=dart" alt="pub.dev"></a>
<a href="https://github.com/SplashByte/cross_fade"><img src="https://img.shields.io/static/v1?label=platform&message=flutter&color=1ebbfd" alt="github"></a>
[![likes](https://img.shields.io/pub/likes/cross_fade)](https://pub.dev/packages/cross_fade/score)
[![popularity](https://img.shields.io/pub/popularity/cross_fade)](https://pub.dev/packages/cross_fade/score)
[![pub points](https://img.shields.io/pub/points/cross_fade)](https://pub.dev/packages/cross_fade/score)
<a href="https://github.com/SplashByte/cross_fade/blob/main/LICENSE"><img src="https://img.shields.io/github/license/SplashByte/cross_fade.svg" alt="license"></a>

[![buy me a coffee](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/splashbyte)

### If you like this package, please leave a like there on [pub.dev](https://pub.dev/packages/cross_fade) and star on [GitHub](https://github.com/SplashByte/cross_fade).

A widget to apply a crossfade animation between different states and/or widgets. It's more flexible than e.g. the official `AnimatedCrossFade`.
Additionally it's really easy to use and efficient.

## Easy Usage

```dart
CrossFade<int>(
    value: value,
    builder: (context, i) => Text('$i'),
)
```

## Examples
![cross_fade_example_1](https://user-images.githubusercontent.com/43761463/155771555-c75a93a1-e1b4-4db1-b5e8-60652364f681.gif)
![cross_fade_example_2](https://user-images.githubusercontent.com/43761463/155771978-0f713562-e10f-494a-a1dd-ec3289bbd7aa.gif)

It also animates between the different sizes of the widgets as you can see here:

![cross_fade_example_3](https://user-images.githubusercontent.com/43761463/155770913-83c59115-cb9e-40a2-80aa-e21ad8c8816e.gif)

So `CrossFade` can be wrapped in anything and it will animate its size along with it:  
```dart
DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(border: Border.all(width: 3.0)),
    child: CrossFade<int>(
        value: index,
        builder: (context, i) => widgets[i],
    ),
),
```
