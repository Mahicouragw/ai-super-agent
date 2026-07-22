import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/pdf_search.dart';
import '../../services/supabase_service.dart';

class PdfSearchScreen extends StatefulWidget {
  const PdfSearchScreen({super.key});

  @override
  State<PdfSearchScreen> createState() => _PdfSearchScreenState();
}

class _PdfSearchScreenState extends State<PdfSearchScreen> {
  final _pdfUtil = PdfSearchUtil();
  final _service = SupabaseService();
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String _status = '';

  Future<void> _pickAndUpload() async {
    setState(() { _loading = true; _status = 'Picking file...'; });
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
      if (res == null) { setState(() => _loading = false); return; }
      final file = res.files.first;
      setState(() => _status = 'Extracting text from ${file.name}...');
      final text = await _pdfUtil.extractTextFromPdf(file);
      setState(() => _status = 'Saving to Supabase securely...');
      await _service.saveDocument(filename: file.name, contentText: text, fileSize: file.size);
      setState(() => _status = '✅ ${file.name} uploaded! ${text.length} chars extracted.');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _search() async {
    if (_searchCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final docs = await _service.searchDocuments(_searchCtrl.text);
      setState(() => _results = docs);
    } catch (e) {
      setState(() => _status = 'Search error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('📄 PDF Search - AI Skill', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Upload PDFs, extract text, semantic search, Q&A', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _loading ? null : _pickAndUpload, icon: const Icon(Icons.upload_file), label: const Text('Upload PDF & Store in Supabase')),
          if (_status.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_status, style: const TextStyle(fontSize: 12))),
          const Divider(),
          TextField(controller: _searchCtrl, decoration: InputDecoration(labelText: 'Search query in PDFs', suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search), border: const OutlineInputBorder())),
          const SizedBox(height: 12),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (c,i) {
                final r = _results[i];
                return Card(child: ListTile(title: Text(r['filename']), subtitle: Text((r['content_text'] as String).length > 200 ? '${(r['content_text'] as String).substring(0,200)}...' : r['content_text'] as String)));
              },
            ),
          )
        ],
      ),
    );
  }
}
