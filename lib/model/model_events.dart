import 'package:drmem_browser/sheet/sheet.dart';

// This is the base class for all events that update the state of the page.

abstract class ModelEvent {
  const ModelEvent();
}

// For this event, we're replacing a row with the one contained in the message.

class UpdateRow extends ModelEvent {
  final int index;
  final BaseRow newRow;

  const UpdateRow(this.index, this.newRow);
}

// For this event, we're inserting a row after the row specified by the index.

class DeleteRow extends ModelEvent {
  final int index;

  const DeleteRow(this.index);
}

class AppendRow extends ModelEvent {
  final BaseRow newRow;

  const AppendRow(this.newRow);
}

class MoveRow extends ModelEvent {
  final int oldIndex;
  final int newIndex;

  const MoveRow(this.oldIndex, this.newIndex);
}

class SelectSheet extends ModelEvent {
  final String name;

  const SelectSheet(this.name);
}

class RenameSelectedSheet extends ModelEvent {
  final String newName;

  const RenameSelectedSheet(this.newName);
}

class AddSheet extends ModelEvent {
  const AddSheet();
}

class DeleteSheet extends ModelEvent {
  const DeleteSheet();
}

class NodeActive extends ModelEvent {}

class NodeInactive extends ModelEvent {
  final String name;

  const NodeInactive(this.name);
}
