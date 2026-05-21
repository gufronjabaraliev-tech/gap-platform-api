import '../models/savings_group.dart';
import 'group_report_export.dart';

/// PDF hisobotdan PNG rasmlar yaratib ulashish.
class GroupReportImageService {
  static Future<void> share(SavingsGroup group) async {
    await GroupReportExportService.shareImage(group);
  }
}
