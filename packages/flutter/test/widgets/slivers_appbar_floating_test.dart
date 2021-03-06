// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void verifyPaintPosition(GlobalKey key, Offset ideal, bool visible) {
  RenderSliver target = key.currentContext.findRenderObject();
  expect(target.parent, new isInstanceOf<RenderViewport2>());
  SliverPhysicalParentData parentData = target.parentData;
  Offset actual = parentData.paintOffset;
  expect(actual, ideal);
  SliverGeometry geometry = target.geometry;
  expect(geometry.visible, visible);
}

void verifyActualBoxPosition(WidgetTester tester, Finder finder, int index, Rect ideal) {
  RenderBox box = tester.renderObjectList<RenderBox>(finder).elementAt(index);
  Rect rect = new Rect.fromPoints(box.localToGlobal(Point.origin), box.localToGlobal(box.size.bottomRight(Point.origin)));
  expect(rect, equals(ideal));
}

void main() {
  testWidgets('Sliver appbars - floating - scroll offset doesn\'t change', (WidgetTester tester) async {
    const double bigHeight = 1000.0;
    await tester.pumpWidget(
      new ScrollableViewport2(
        axisDirection: AxisDirection.down,
        slivers: <Widget>[
          new BigSliver(height: bigHeight),
          new SliverAppBar(delegate: new TestDelegate(), floating: true),
          new BigSliver(height: bigHeight),
        ],
      ),
    );
    AbsoluteScrollPosition position = tester.state<Scrollable2State>(find.byType(Scrollable2)).position;
    final double max = bigHeight * 2.0 + new TestDelegate().maxExtent - 600.0; // 600 is the height of the test viewport
    assert(max < 10000.0);
    expect(max, 1600.0);
    expect(position.pixels, 0.0);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
    position.animate(to: 10000.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 10));
    expect(position.pixels, max);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
  });

  testWidgets('Sliver appbars - floating - normal behavior works', (WidgetTester tester) async {
    final TestDelegate delegate = new TestDelegate();
    const double bigHeight = 1000.0;
    GlobalKey key1, key2, key3;
    await tester.pumpWidget(
      new ScrollableViewport2(
        axisDirection: AxisDirection.down,
        slivers: <Widget>[
          new BigSliver(key: key1 = new GlobalKey(), height: bigHeight),
          new SliverAppBar(key: key2 = new GlobalKey(), delegate: delegate, floating: true),
          new BigSliver(key: key3 = new GlobalKey(), height: bigHeight),
        ],
      ),
    );
    AbsoluteScrollPosition position = tester.state<Scrollable2State>(find.byType(Scrollable2)).position;

    verifyPaintPosition(key1, new Offset(0.0, 0.0), true);
    verifyPaintPosition(key2, new Offset(0.0, 600.0), false);
    verifyPaintPosition(key3, new Offset(0.0, 600.0), false);

    position.animate(to: bigHeight - 600.0 + delegate.maxExtent, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, new Offset(0.0, 0.0), true);
    verifyPaintPosition(key2, new Offset(0.0, 600.0 - delegate.maxExtent), true);
    verifyActualBoxPosition(tester, find.byType(Container), 0, new Rect.fromLTWH(0.0, 600.0 - delegate.maxExtent, 800.0, delegate.maxExtent));
    verifyPaintPosition(key3, new Offset(0.0, 600.0), false);

    assert(delegate.maxExtent * 2.0 < 600.0); // make sure this fits on the test screen...
    position.animate(to: bigHeight - 600.0 + delegate.maxExtent * 2.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, new Offset(0.0, 0.0), true);
    verifyPaintPosition(key2, new Offset(0.0, 600.0 - delegate.maxExtent * 2.0), true);
    verifyActualBoxPosition(tester, find.byType(Container), 0, new Rect.fromLTWH(0.0, 600.0 - delegate.maxExtent * 2.0, 800.0, delegate.maxExtent));
    verifyPaintPosition(key3, new Offset(0.0, 600.0 - delegate.maxExtent), true);

    position.animate(to: bigHeight, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, new Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, new Offset(0.0, 0.0), true);
    verifyActualBoxPosition(tester, find.byType(Container), 0, new Rect.fromLTWH(0.0, 0.0, 800.0, delegate.maxExtent));
    verifyPaintPosition(key3, new Offset(0.0, delegate.maxExtent), true);

    position.animate(to: bigHeight + delegate.maxExtent * 0.1, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, new Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, new Offset(0.0, 0.0), true);
    verifyActualBoxPosition(tester, find.byType(Container), 0, new Rect.fromLTWH(0.0, 0.0, 800.0, delegate.maxExtent * 0.9));
    verifyPaintPosition(key3, new Offset(0.0, delegate.maxExtent * 0.9), true);

    position.animate(to: bigHeight + delegate.maxExtent * 0.5, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, new Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, new Offset(0.0, 0.0), true);
    verifyActualBoxPosition(tester, find.byType(Container), 0, new Rect.fromLTWH(0.0, 0.0, 800.0, delegate.maxExtent * 0.5));
    verifyPaintPosition(key3, new Offset(0.0, delegate.maxExtent * 0.5), true);

    position.animate(to: bigHeight + delegate.maxExtent * 0.9, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, new Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, new Offset(0.0, 0.0), true);
    verifyActualBoxPosition(tester, find.byType(Container), 0, new Rect.fromLTWH(0.0, -delegate.maxExtent * 0.4, 800.0, delegate.maxExtent * 0.5));
    verifyPaintPosition(key3, new Offset(0.0, delegate.maxExtent * 0.1), true);

    position.animate(to: bigHeight + delegate.maxExtent * 2.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, new Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, new Offset(0.0, 0.0), false);
    verifyPaintPosition(key3, new Offset(0.0, 0.0), true);
  });

  testWidgets('Sliver appbars - floating - no floating behavior when animating', (WidgetTester tester) async {
    final TestDelegate delegate = new TestDelegate();
    const double bigHeight = 1000.0;
    GlobalKey key1, key2, key3;
    await tester.pumpWidget(
      new ScrollableViewport2(
        axisDirection: AxisDirection.down,
        slivers: <Widget>[
          new BigSliver(key: key1 = new GlobalKey(), height: bigHeight),
          new SliverAppBar(key: key2 = new GlobalKey(), delegate: delegate, floating: true),
          new BigSliver(key: key3 = new GlobalKey(), height: bigHeight),
        ],
      ),
    );
    AbsoluteScrollPosition position = tester.state<Scrollable2State>(find.byType(Scrollable2)).position;

    verifyPaintPosition(key1, new Offset(0.0, 0.0), true);
    verifyPaintPosition(key2, new Offset(0.0, 600.0), false);
    verifyPaintPosition(key3, new Offset(0.0, 600.0), false);

    position.animate(to: bigHeight + delegate.maxExtent * 2.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, new Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, new Offset(0.0, 0.0), false);
    verifyPaintPosition(key3, new Offset(0.0, 0.0), true);

    position.animate(to: bigHeight + delegate.maxExtent * 1.9, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, new Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, new Offset(0.0, 0.0), false);
    verifyPaintPosition(key3, new Offset(0.0, 0.0), true);
  });

  testWidgets('Sliver appbars - floating - floating behavior when dragging down', (WidgetTester tester) async {
    final TestDelegate delegate = new TestDelegate();
    const double bigHeight = 1000.0;
    GlobalKey key1, key2, key3;
    await tester.pumpWidget(
      new ScrollableViewport2(
        axisDirection: AxisDirection.down,
        slivers: <Widget>[
          new BigSliver(key: key1 = new GlobalKey(), height: bigHeight),
          new SliverAppBar(key: key2 = new GlobalKey(), delegate: delegate, floating: true),
          new BigSliver(key: key3 = new GlobalKey(), height: bigHeight),
        ],
      ),
    );
    AbsoluteScrollPosition position = tester.state<Scrollable2State>(find.byType(Scrollable2)).position;

    verifyPaintPosition(key1, new Offset(0.0, 0.0), true);
    verifyPaintPosition(key2, new Offset(0.0, 600.0), false);
    verifyPaintPosition(key3, new Offset(0.0, 600.0), false);

    position.animate(to: bigHeight + delegate.maxExtent * 2.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, new Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, new Offset(0.0, 0.0), false);
    verifyPaintPosition(key3, new Offset(0.0, 0.0), true);

    position.animate(to: bigHeight + delegate.maxExtent * 1.9, curve: Curves.linear, duration: const Duration(minutes: 1));
    position.updateUserScrollDirection(ScrollDirection.forward); // ignore: INVALID_USE_OF_PROTECTED_MEMBER, since this is using a protected method for testing purposes
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, new Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, new Offset(0.0, 0.0), true);
    verifyActualBoxPosition(tester, find.byType(Container), 0, new Rect.fromLTWH(0.0, -delegate.maxExtent * 0.4, 800.0, delegate.maxExtent * 0.5));
    verifyPaintPosition(key3, new Offset(0.0, 0.0), true);
  });
}

class TestDelegate extends SliverAppBarDelegate {
  @override
  double get maxExtent => 200.0;

  @override
  Widget build(BuildContext context, double shrinkOffset) {
    return new Container(constraints: new BoxConstraints(minHeight: maxExtent / 2.0, maxHeight: maxExtent));
  }

  @override
  bool shouldRebuild(TestDelegate oldDelegate) => false;
}


class RenderBigSliver extends RenderSliver {
  RenderBigSliver(double height) : _height = height;

  double get height => _height;
  double _height;
  set height(double value) {
    if (value == _height)
      return;
    _height = value;
    markNeedsLayout();
  }

  double get paintExtent => (height - constraints.scrollOffset).clamp(0.0, constraints.remainingPaintExtent);

  @override
  void performLayout() {
    geometry = new SliverGeometry(
      scrollExtent: height,
      paintExtent: paintExtent,
      maxPaintExtent: height,
    );
  }
}

class BigSliver extends LeafRenderObjectWidget {
  BigSliver({ Key key, this.height }) : super(key: key);

  final double height;

  @override
  RenderBigSliver createRenderObject(BuildContext context) {
    return new RenderBigSliver(height);
  }

  @override
  void updateRenderObject(BuildContext context, RenderBigSliver renderObject) {
    renderObject.height = height;
  }
}
