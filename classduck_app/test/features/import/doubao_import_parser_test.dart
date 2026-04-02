import 'package:classduck_app/features/import/application/doubao_import_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DoubaoImportParser', () {
    test('parses fenced json with textual week ranges', () {
      const String source = '''```json
{
  "table_name": "2025-2026-1",
  "courses": [
    {
      "name": "高等数学",
      "teacher": "张老师",
      "classroom": "教1-101",
      "day": 1,
      "sections": "1-2节",
      "weeks": "1-8周,10-16周(双)"
    }
  ]
}
```''';

      final table = DoubaoImportParser.parse(source);

      expect(table.name, '2025-2026-1');
      expect(table.courses, hasLength(1));
      expect(table.courses.first.name, '高等数学');
      expect(table.courses.first.startTime, 1);
      expect(table.courses.first.timeCount, 2);
      expect(table.courses.first.weeks, <int>[1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16]);
    });

    test('supports top level array and fallback table name', () {
      const String source = '''[
  {
    "course_name": "大学英语",
    "teacher": "李老师",
    "location": "教2-203",
    "weekday": "星期三",
    "start_section": 3,
    "duration": 2,
    "weeks": [1, 2, 3, 4]
  }
]''';

      final table = DoubaoImportParser.parse(
        source,
        fallbackTableName: '豆包导入课表',
      );

      expect(table.name, '豆包导入课表');
      expect(table.courses, hasLength(1));
      expect(table.courses.first.weekTime, 3);
      expect(table.courses.first.classroom, '教2-203');
    });

    test('supports compact key contract n d s e w l t', () {
      const String source = '''[
  {"n":"大学英语(4)","d":3,"s":3,"e":4,"w":"1-8,10,12","l":"B202","t":"李四"},
  {"n":"实验课","d":5,"s":5,"e":8,"w":"1-16","l":null,"t":null}
]''';

      final table = DoubaoImportParser.parse(source);

      expect(table.courses, hasLength(2));
      expect(table.courses.first.name, '大学英语(4)');
      expect(table.courses.first.timeCount, 2);
      expect(table.courses.first.weeks, <int>[1, 2, 3, 4, 5, 6, 7, 8, 10, 12]);
      expect(table.courses.last.timeCount, 4);
      expect(table.courses.last.classroom, isNull);
    });

    // ── 异常路径测试 ──

    test('throws FormatException on empty input', () {
      expect(
        () => DoubaoImportParser.parse(''),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => DoubaoImportParser.parse('   '),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException on invalid JSON', () {
      expect(
        () => DoubaoImportParser.parse('这不是JSON'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => DoubaoImportParser.parse('{invalid json}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when courses array is missing', () {
      expect(
        () => DoubaoImportParser.parse('{"name": "测试课表"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when course lacks name', () {
      const String source = '[{"d":1,"s":1,"e":2,"w":"1-16"}]';
      expect(
        () => DoubaoImportParser.parse(source),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when course lacks weekday', () {
      const String source = '[{"n":"数学","s":1,"e":2,"w":"1-16"}]';
      expect(
        () => DoubaoImportParser.parse(source),
        throwsA(isA<FormatException>()),
      );
    });

    test('correctly expands odd/even week patterns', () {
      const String source = '''[
  {"n":"单周课","d":1,"s":1,"e":2,"w":"1-10周(单)","l":null,"t":null},
  {"n":"双周课","d":2,"s":3,"e":4,"w":"2-10周(双)","l":null,"t":null}
]''';

      final table = DoubaoImportParser.parse(source);

      expect(table.courses[0].weeks, <int>[1, 3, 5, 7, 9]);
      expect(table.courses[1].weeks, <int>[2, 4, 6, 8, 10]);
    });
  });
}