import 'dart:typed_data';

import '../models/savings_group.dart';
import 'group_report_export_io.dart'
    if (dart.library.html) 'group_report_export_web.dart';
import 'group_report_pdf_service.dart';

/// PDF / rasm hisobotini platformaga mos saqlash yoki ulashish.
class GroupReportExportService {
  static Future<void> sharePdf(SavingsGroup group) async {
    final bytes = Uint8List.fromList(
      await GroupReportPdfService.buildBytes(group),
    );
    final name = GroupReportPdfService.fileNameFor(group);
    await exportPlatformPdf(bytes, name, group.name);
  }

  static Future<void> shareImage(SavingsGroup group) async {
    final pdfBytes = Uint8List.fromList(
      await GroupReportPdfService.buildBytes(group),
    );
    final baseName =
        GroupReportPdfService.fileNameFor(group).replaceAll('.pdf', '');
    await exportPlatformImages(pdfBytes, baseName, group.name);
  }
}
