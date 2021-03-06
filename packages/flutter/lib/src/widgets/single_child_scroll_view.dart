// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'scrollable.dart';

class SingleChildScrollView extends StatelessWidget {
  SingleChildScrollView({
    Key key,
    this.scrollDirection: Axis.vertical,
    this.initialScrollOffset: 0.0,
    this.child,
  }) : super(key: key) {
    assert(scrollDirection != null);
    assert(initialScrollOffset != null);
  }

  final Axis scrollDirection;

  final double initialScrollOffset;

  final Widget child;

  AxisDirection _getDirection(BuildContext context) {
    // TODO(abarth): Consider reading direction.
    switch (scrollDirection) {
      case Axis.horizontal:
        return AxisDirection.right;
      case Axis.vertical:
        return AxisDirection.down;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final AxisDirection axisDirection = _getDirection(context);
    return new Scrollable2(
      axisDirection: axisDirection,
      initialScrollOffset: initialScrollOffset,
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        return new _SingleChildViewport(
          key: key,
          axisDirection: axisDirection,
          offset: offset,
          child: child,
        );
      },
    );
  }
}

class _SingleChildViewport extends SingleChildRenderObjectWidget {
  _SingleChildViewport({
    Key key,
    this.axisDirection: AxisDirection.down,
    this.offset,
    Widget child,
  }) : super(key: key, child: child) {
    assert(axisDirection != null);
  }

  final AxisDirection axisDirection;
  final ViewportOffset offset;

  @override
  _RenderSingleChildViewport createRenderObject(BuildContext context) {
    return new _RenderSingleChildViewport(
      axisDirection: axisDirection,
      offset: offset,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSingleChildViewport renderObject) {
    // Order dependency: The offset setter reads the axis direction.
    renderObject
      ..axisDirection = axisDirection
      ..offset = offset;
  }
}

class _RenderSingleChildViewport extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  _RenderSingleChildViewport({
    AxisDirection axisDirection: AxisDirection.down,
    ViewportOffset offset,
    RenderBox child,
  }) : _axisDirection = axisDirection,
       _offset = offset {
    assert(axisDirection != null);
    assert(offset != null);
    this.child = child;
  }

  AxisDirection get axisDirection => _axisDirection;
  AxisDirection _axisDirection;
  set axisDirection(AxisDirection value) {
    assert(value != null);
    if (value == _axisDirection)
      return;
    _axisDirection = value;
    markNeedsLayout();
  }

  Axis get axis => axisDirectionToAxis(axisDirection);

  ViewportOffset get offset => _offset;
  ViewportOffset _offset;
  set offset(ViewportOffset value) {
    assert(value != null);
    if (value == _offset)
      return;
    if (attached)
      _offset.removeListener(markNeedsLayout);
    if (_offset.pixels != value.pixels)
      markNeedsLayout();
    _offset = value;
    if (attached)
      _offset.addListener(markNeedsLayout);
    // If we already have a size, then we should re-report the dimensions
    // to the new ViewportOffset. If we don't then we'll report them when
    // we establish the dimensions later, so don't worry about it now.
    if (hasSize) {
      assert(_minScrollExtent != null);
      assert(_maxScrollExtent != null);
      assert(_effectiveExtent != null);
      offset.applyViewportDimension(_effectiveExtent);
      if (offset.applyContentDimensions(_minScrollExtent, _maxScrollExtent))
        markNeedsPaint();
    }
  }

  @override
  void setupParentData(RenderObject child) {
    // We don't actually use the offset argument in BoxParentData, so let's
    // avoid allocating it at all.
    if (child.parentData is! ParentData)
      child.parentData = new ParentData();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _offset.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get isRepaintBoundary => true;

  double get _effectiveExtent {
    assert(hasSize);
    switch (axis) {
      case Axis.vertical:
        return size.height;
      case Axis.horizontal:
        return size.width;
    }
    return null;
  }


  double get _minScrollExtent {
    assert(hasSize);
    return 0.0;
  }

  double get _maxScrollExtent {
    assert(hasSize);
    if (child == null)
      return 0.0;
    return math.max(0.0, child.size.height - size.height);
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    switch (axis) {
      case Axis.horizontal:
        return constraints.heightConstraints();
      case Axis.vertical:
        return constraints.widthConstraints();
    }
    return null;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child != null)
      return child.getMinIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child != null)
      return child.getMaxIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null)
      return child.getMinIntrinsicHeight(width);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null)
      return child.getMaxIntrinsicHeight(width);
    return 0.0;
  }

  // We don't override computeDistanceToActualBaseline(), because we
  // want the default behavior (returning null). Otherwise, as you
  // scroll, it would shift in its parent if the parent was baseline-aligned,
  // which makes no sense.

  @override
  void performLayout() {
    if (child == null) {
      size = constraints.smallest;
    } else {
      child.layout(_getInnerConstraints(constraints), parentUsesSize: true);
      size = constraints.constrain(child.size);
    }

    offset.applyViewportDimension(_effectiveExtent);
    offset.applyContentDimensions(_minScrollExtent, _maxScrollExtent);
  }

  Offset get _scrollOffsetAsOffset {
    assert(axisDirection != null);
    switch (axisDirection) {
      case AxisDirection.up:
        return new Offset(0.0, _offset.pixels);
      case AxisDirection.down:
        return new Offset(0.0, -_offset.pixels);
      case AxisDirection.left:
        return new Offset(_offset.pixels, 0.0);
      case AxisDirection.right:
        return new Offset(-_offset.pixels, 0.0);
    }
    return null;
  }

  bool _shouldClipAtPaintOffset(Offset paintOffset) {
    assert(child != null);
    return paintOffset < Offset.zero || !(Offset.zero & size).contains((paintOffset & child.size).bottomRight);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final Offset paintOffset = _scrollOffsetAsOffset;

      void paintContents(PaintingContext context, Offset offset) {
        context.paintChild(child, offset + paintOffset);
      }

      if (_shouldClipAtPaintOffset(paintOffset)) {
        context.pushClipRect(needsCompositing, offset, Point.origin & size, paintContents);
      } else {
        paintContents(context, offset);
      }
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final Offset paintOffset = _scrollOffsetAsOffset;
    transform.translate(paintOffset.dx, paintOffset.dy);
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) {
    if (child != null && _shouldClipAtPaintOffset(_scrollOffsetAsOffset))
      return Point.origin & size;
    return null;
  }

  @override
  bool hitTestChildren(HitTestResult result, { Point position }) {
    if (child != null) {
      final Point transformed = position + -_scrollOffsetAsOffset;
      return child.hitTest(result, position: transformed);
    }
    return false;
  }
}
