import 'package:flutter/material.dart';
import 'package:learningexamapp/utils/common_widgets/NoScreenshotWrapper.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFViewerPage extends StatelessWidget {
  final String fileUrl;
  final String fileName;

  const PDFViewerPage({
    required this.fileUrl,
    required this.fileName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return NoScreenshotWrapper(
      child: Scaffold(
        appBar: AppBar(title: Text(fileName)),
        body: SfPdfViewer.network(fileUrl),
      ),
    );
  }
}
