import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';

class EditableImage {
  XFile file;
  Uint8List bytes;
  double dx = 0.0;
  double dy = 0.0;
  double scale = 1.0;

  EditableImage({required this.file, required this.bytes});
}

void main() => runApp(MaterialApp(home: MedicalReportPage(), debugShowCheckedModeBanner: false));

class MedicalReportPage extends StatefulWidget {
  @override
  _MedicalReportPageState createState() => _MedicalReportPageState();
}

class _MedicalReportPageState extends State<MedicalReportPage> {
  final _nameController = TextEditingController();
  final _physicianController = TextEditingController();
  final _dateController = TextEditingController();
  final _ageController = TextEditingController();
  final _procedureController = TextEditingController(text: "Colonoscopy");
  
  List<EditableImage> _editableImages = [];

  Future<void> _pickImages() async {
    final List<XFile> images = await ImagePicker().pickMultiImage();
    if (images.isNotEmpty) {
      for (var img in images) {
        if (_editableImages.length < 6) {
          final bytes = await img.readAsBytes();
          setState(() {
            _editableImages.add(EditableImage(file: img, bytes: bytes));
          });
        }
      }
    }
  }

  void _reorder(int oldIndex, int direction) {
    int newIndex = oldIndex + direction;
    if (newIndex < 0 || newIndex >= _editableImages.length) return;
    setState(() {
      final item = _editableImages.removeAt(oldIndex);
      _editableImages.insert(newIndex, item);
    });
  }

  void _generatePdf() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(children: [
                pw.Expanded(child: pw.Text('PATIENT NAME: ${_nameController.text.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Expanded(child: pw.Text('DATE OF PROCEDURE: ${_dateController.text}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ]),
              pw.SizedBox(height: 8),
              pw.Row(children: [
                pw.Expanded(child: pw.Text('GASTROENTEROLOGIST: ${_physicianController.text.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Expanded(child: pw.Text('AGE: ${_ageController.text} YEARS OLD', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ]),
              pw.SizedBox(height: 15),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 15),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(color: PdfColors.blueGrey800, borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Text(_procedureController.text.toUpperCase(), 
                  style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ),
              pw.SizedBox(height: 25),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Wrap(
                  spacing: 15, runSpacing: 15,
                  alignment: pw.WrapAlignment.center,
                  children: _editableImages.map((img) {
                    return pw.Container(
                      width: 230, height: 170,
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                      child: pw.Image(
                        pw.MemoryImage(img.bytes),
                        fit: pw.BoxFit.cover,
                      ),
                    );
                  }).toList(),
                ),
              ),
              pw.Spacer(),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Medical Report Editor"), backgroundColor: Colors.blueGrey),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: "Patient Name", border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(controller: _ageController, decoration: InputDecoration(labelText: "Age (numerical)", border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(controller: _physicianController, decoration: InputDecoration(labelText: "Gastroenterologist", border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(controller: _procedureController, decoration: InputDecoration(labelText: "Procedure", border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(labelText: "Date", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
              onTap: () async {
                DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
                if (picked != null) setState(() => _dateController.text = "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year.toString().substring(2)}");
              },
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(onPressed: _pickImages, icon: Icon(Icons.add_a_photo), label: Text("Add Images (Max 6)")),

            if (_editableImages.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _editableImages.length,
                itemBuilder: (context, index) {
                  final img = _editableImages[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 140,
                            child: AspectRatio(
                              aspectRatio: 230 / 170,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.memory(
                                    img.bytes,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(icon: Icon(Icons.arrow_upward), onPressed: () => _reorder(index, -1)),
                                IconButton(icon: Icon(Icons.arrow_downward), onPressed: () => _reorder(index, 1)),
                                IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _editableImages.removeAt(index))),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _generatePdf,
              child: Text("GENERATE PDF"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: Size(double.infinity, 60)),
            ),
          ],
        ),
      ),
    );
  }
}