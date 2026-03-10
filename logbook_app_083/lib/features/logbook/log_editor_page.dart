import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_083/features/logbook/models/log_model.dart';
import 'package:logbook_app_083/features/logbook/log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final String username;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.username,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;

  String _selectedCategory = "Mechanical";
  final List<String> _categories = ["Mechanical", "Electronic", "Software"];
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );
    if (widget.log != null) {
      if (_categories.contains(widget.log!.category)) {
        _selectedCategory = widget.log!.category;
      } else {
        _selectedCategory = "Mechanical";
      }
      _isPublic = widget.log!.isPublic;
    }
    // TAMBAHKAN INI: Listener agar Pratinjau terupdate otomatis
    _descController.addListener(() {
      setState(() {});
    });
  }

  void _save() {
    if (widget.log == null) {
      // Tambah Baru
      widget.controller.addLog(
        _titleController.text,
        _descController.text,
        _selectedCategory,
        _isPublic,
      );
    } else {
      // Update
      widget.controller.updateLog(
        widget.index!,
        _titleController.text,
        _descController.text,
        _selectedCategory,
        _isPublic,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.log == null
              ? "Catatan berhasil ditambahkan!"
              : "Catatan berhasil diperbarui!",
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    // JANGAN LUPA: Bersihkan controller agar tidak memory leak
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      labelText: hint,
      filled: true,
      fillColor: const Color(0xFFF0F4FF),
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.log == null ? "Catatan Baru" : "Edit Catatan"),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Editor", icon: Icon(Icons.edit_note_rounded)),
              Tab(text: "Pratinjau", icon: Icon(Icons.preview_rounded)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save_rounded),
              tooltip: "Simpan",
              onPressed: _save,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Editor
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: _fieldDecoration(
                      "Judul Catatan",
                      icon: Icons.title_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: _fieldDecoration(
                      "Kategori",
                      icon: Icons.label_outline_rounded,
                    ),
                    items: _categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isPublic
                                  ? Icons.public_rounded
                                  : Icons.lock_outline_rounded,
                              size: 20,
                              color: _isPublic
                                  ? Colors.green[600]
                                  : Colors.blueGrey,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isPublic
                                  ? "Publik (Tim bisa lihat)"
                                  : "Privat (Hanya Anda)",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isPublic,
                          activeColor: Colors.green[600],
                          onChanged: (val) {
                            setState(() {
                              _isPublic = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _descController,
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText:
                              "Tulis laporan dengan format Markdown...\n\nContoh:\n# Judul Besar\n**Teks Tebal**\n- Butir 1\n- Butir 2",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab 2: Markdown Preview
            Container(
              color: Colors.white,
              child: _descController.text.isEmpty
                  ? const Center(
                      child: Text(
                        "Preview kosong.\nTulislah sesuatu di tab Editor.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : Markdown(
                      data: _descController.text,
                      padding: const EdgeInsets.all(16),
                      selectable: true,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}