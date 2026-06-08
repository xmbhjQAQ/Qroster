import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/parsed_roster_entry.dart';

class ImportService {
  List<ParsedRosterEntry> parsePlainText(String text) {
    return text
        .split(RegExp(r'\r?\n'))
        .map(_parseLine)
        .where((entry) => entry.isValid)
        .toList();
  }

  List<ParsedRosterEntry> parseSpreadsheetBytes(Uint8List bytes) {
    final workbook = Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      return const [];
    }

    final sheet = workbook.tables.values.first;
    if (sheet.rows.isEmpty) {
      return const [];
    }

    final rows = sheet.rows
        .map((row) => row.map((cell) => _cellText(cell?.value)).toList())
        .toList();
    final header = rows.first;
    final nameColumn = _nameColumnIndex(header);
    final hasHeader = _looksLikeHeader(header);
    final dataRows = hasHeader ? rows.skip(1) : rows;

    return dataRows.map((row) {
      final displayName =
          nameColumn < row.length ? row[nameColumn].trim() : '';
      final note = row
          .asMap()
          .entries
          .where((entry) => entry.key != nameColumn)
          .map((entry) => entry.value.trim())
          .where((value) => value.isNotEmpty)
          .join(' / ');
      return ParsedRosterEntry(displayName: displayName, note: note);
    }).where((entry) => entry.isValid).toList();
  }

  String spreadsheetBytesToText(Uint8List bytes) {
    final workbook = Excel.decodeBytes(bytes);
    final buffer = StringBuffer();
    for (final table in workbook.tables.entries) {
      final sheet = table.value;
      buffer.writeln('Sheet: ${table.key}');
      for (var rowIndex = 0; rowIndex < sheet.rows.length; rowIndex += 1) {
        final cells = sheet.rows[rowIndex]
            .map((cell) => _cellText(cell?.value).trim())
            .toList();
        if (cells.every((cell) => cell.isEmpty)) {
          continue;
        }
        buffer.writeln('Row ${rowIndex + 1}: ${cells.join(' | ')}');
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  ParsedRosterEntry _parseLine(String line) {
    final cleaned = line.trim();
    if (cleaned.isEmpty) {
      return const ParsedRosterEntry(displayName: '');
    }

    final parts = cleaned
        .split(RegExp(r'[\t,，;；|]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return const ParsedRosterEntry(displayName: '');
    }
    return ParsedRosterEntry(
      displayName: parts.first,
      note: parts.skip(1).join(' / '),
    );
  }

  int _nameColumnIndex(List<String> header) {
    final index = header.indexWhere((cell) {
      final normalized = cell.trim().toLowerCase();
      return normalized.contains('姓名') ||
          normalized.contains('名字') ||
          normalized == 'name' ||
          normalized.contains('display name');
    });
    if (index >= 0) {
      return index;
    }
    return header.indexWhere((cell) => cell.trim().isNotEmpty).clamp(0, 999);
  }

  bool _looksLikeHeader(List<String> row) {
    return row.any((cell) {
      final normalized = cell.trim().toLowerCase();
      return normalized.contains('姓名') ||
          normalized.contains('名字') ||
          normalized == 'name' ||
          normalized.contains('备注') ||
          normalized.contains('note');
    });
  }

  String _cellText(CellValue? value) {
    return switch (value) {
      null => '',
      TextCellValue() => value.value.text ?? '',
      IntCellValue() => value.value.toString(),
      DoubleCellValue() => value.value.toString(),
      DateCellValue() => value.asDateTimeLocal().toIso8601String(),
      DateTimeCellValue() => value.asDateTimeLocal().toIso8601String(),
      BoolCellValue() => value.value ? 'TRUE' : 'FALSE',
      TimeCellValue() => value.toString(),
      FormulaCellValue() => value.formula,
    };
  }
}
