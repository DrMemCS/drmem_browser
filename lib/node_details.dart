import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart';

// Creates a widget that displays the information associated with a node.

Widget displayNode(Service node) {
  return Text('You picked: ${node.name}');
}
