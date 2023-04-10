import 'package:flutter/material.dart';
import 'package:drmem_browser/sheet/sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("Testing bad input", () {
    test("... bad row type", () {
      expect(BaseRow.fromJson({'type': 'junk'}), null);
    });
    test("... bad comment field type", () {
      expect(BaseRow.fromJson({'type': 'comment'}), null);
      expect(BaseRow.fromJson({'type': 'comment', 'junk': true}), null);
    });
    test("... bad device field type", () {
      expect(BaseRow.fromJson({'type': 'device'}), null);
      expect(BaseRow.fromJson({'type': 'device', 'label': true}), null);
      expect(BaseRow.fromJson({'type': 'device', 'junk': true}), null);
    });
  });

  group("Testing row serialization", () {
    test("... EmptyRow", () {
      final EmptyRow tmp = EmptyRow(key: UniqueKey());
      final EmptyRow out =
          BaseRow.fromJson(tmp.toJson(), key: tmp.key) as EmptyRow;

      expect(out.key, tmp.key);
    });

    test("... DeviceRow", () {
      // Test serialization of a device row which doesn't have a label.

      {
        final DeviceRow tmp = DeviceRow("device:state", key: UniqueKey());
        final json = tmp.toJson();

        // Make sure that, when the label is null, we don't emit anything for
        // that field.

        expect(json.containsKey("label"), false);

        final DeviceRow out = BaseRow.fromJson(json, key: tmp.key) as DeviceRow;

        expect(out.name, tmp.name);
        expect(out.label, null);
        expect(out.key, tmp.key);
      }

      // Test serialization of a device row which has a label.

      {
        final DeviceRow tmp =
            DeviceRow("device:state", label: "tag", key: UniqueKey());
        final DeviceRow out =
            BaseRow.fromJson(tmp.toJson(), key: tmp.key) as DeviceRow;

        expect(out.name, tmp.name);
        expect(out.label, tmp.label);
        expect(out.key, tmp.key);
      }
    });

    test("... CommentRow", () {
      final CommentRow tmp = CommentRow("This is a comment.", key: UniqueKey());
      final CommentRow out =
          BaseRow.fromJson(tmp.toJson(), key: tmp.key) as CommentRow;

      expect(out.comment, tmp.comment);
      expect(out.key, tmp.key);
    });

    test("... PlotRow", () {
      final PlotRow tmp = PlotRow(key: UniqueKey());
      final PlotRow out =
          BaseRow.fromJson(tmp.toJson(), key: tmp.key) as PlotRow;

      expect(out.key, tmp.key);
    });
  });
}
