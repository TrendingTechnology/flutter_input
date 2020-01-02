// Copyright 2020 Hajo.Lemcke@mail.com
// Please see the LICENSE file for details.

import 'package:flutter/material.dart';

import 'input_form.dart';

/// Provides a slider to select a value of type double between a given minimum and a given maximum.
///
/// See
class InputSlider extends InputField<double> {
  final Color activeColor, inactiveColor;
  final int divisions;
  final double min, max;

  InputSlider({
    Key key,
    this.activeColor,
    bool autovalidate = false,
    this.divisions,
    InputDecoration decoration,
    bool enabled,
    this.inactiveColor,
    double initialValue,
    this.min = 0.0,
    this.max = 100.0,
    ValueChanged<double> onChanged,
    ValueSetter<double> onSaved,
    String path,
    List<InputValidator> validators,
  })  : assert(min < max),
        super(
          key: key,
          autovalidate: autovalidate,
          decoration: decoration,
          enabled: enabled,
          initialValue: initialValue,
          onChanged: onChanged,
          onSaved: onSaved,
          path: path,
          validators: validators,
        );

  @override
  _InputSliderState createState() => _InputSliderState();
}

class _InputSliderState extends InputFieldState<double> {
  @override
  InputSlider get widget => super.widget;

  @override
  Widget build(BuildContext context) {
    return super.buildInputField(
      context,
      Slider.adaptive(
        activeColor: widget.activeColor,
        divisions: widget.divisions,
        inactiveColor: widget.inactiveColor,
        label: value?.floor().toString() ?? widget.min.toString(),
        min: widget.min,
        max: widget.max,
        onChanged: super.isEnabled() ? (v) => super.didChange(v) : null,
        value: value ?? widget.initialValue ?? widget.min,
      ),
    );
  }
}
