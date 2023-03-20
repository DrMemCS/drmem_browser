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
      expect(BaseRow.fromJson({'type': 'device', 'junk': true}), null);
    });
  });

  group("Testing row serialization", () {
    test("... EmptyRow", () {
      expect(BaseRow.fromJson(const EmptyRow().toJson()), const EmptyRow());
    });

    test("... DeviceRow", () {
      const DeviceRow tmp = DeviceRow("This is a comment.");
      DeviceRow out = BaseRow.fromJson(tmp.toJson()) as DeviceRow;

      expect(out.name, tmp.name);
    });

    test("... CommentRow", () {
      const CommentRow tmp = CommentRow("This is a comment.");
      CommentRow out = BaseRow.fromJson(tmp.toJson()) as CommentRow;

      expect(out.comment, tmp.comment);
    });

    test("... PlotRow", () {
      expect(BaseRow.fromJson(const PlotRow().toJson()), const PlotRow());
    });
  });
}
