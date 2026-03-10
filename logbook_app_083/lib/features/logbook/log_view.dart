import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logbook_app_083/helpers/log_helper.dart';
import 'package:logbook_app_083/services/mongo_service.dart';
import 'package:logbook_app_083/services/access_control_service.dart';
import 'log_controller.dart';
import 'log_editor_page.dart';
import 'models/log_model.dart';
import '../onboarding/onboarding_view.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController _controller;
  bool _isLoading = false;
  String? _errorMessage; 
  bool _isOffline = false; 

  // 1. Tambahkan Controller untuk menangkap input di dalam State
  final TextEditingController _searchController = TextEditingController();

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Pekerjaan": return Colors.orange;
      case "Tugas": return Colors.red;
      default: return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "Pekerjaan":
        return Icons.work_outline_rounded;
      case "Tugas":
        return Icons.assignment_outlined;
      default:
        return Icons.person_outline_rounded;
    }
  }

  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          username: widget.username,
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const OnboardingView()),
                (route) => false,
              );
            },
            child: const Text("Ya, Keluar"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = LogController(
      username: widget.username,
      userRole: widget.username == 'admin' ? 'Ketua' : 'Anggota',
    );

    // Memberikan kesempatan UI merender widget awal sebelum proses berat dimulai
    Future.microtask(() => _initDatabase());
  }

  Future<void> _initDatabase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isOffline = false;
    });
    try {
      await LogHelper.writeLog(
        "UI: Memulai inisialisasi database...",
        source: "log_view.dart",
      );

      // Mencoba koneksi ke MongoDB Atlas (Cloud)
      await LogHelper.writeLog(
        "UI: Menghubungi MongoService.connect()...",
        source: "log_view.dart",
      );

      // Mengaktifkan kembali koneksi dengan timeout 15 detik (lebih longgar untuk sinyal HP)
      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception(
          "Koneksi Cloud Timeout. Periksa sinyal/IP Whitelist.",
        ),
      );

      await LogHelper.writeLog(
        "UI: Koneksi MongoService BERHASIL.",
        source: "log_view.dart",
      );

      // Mengambil data log dari Cloud
      await LogHelper.writeLog(
        "UI: Memanggil controller.loadFromDisk()...",
        source: "log_view.dart",
      );

      await _controller.loadFromDisk();

      await LogHelper.writeLog(
        "UI: Data berhasil dimuat ke Notifier.",
        source: "log_view.dart",
      );
    } catch (e) {
      final errorStr = e.toString();
      final isNetworkError =
          errorStr.contains('Timeout') ||
          errorStr.contains('SocketException') ||
          errorStr.contains('Network') ||
          errorStr.contains('connection') ||
          errorStr.contains('Whitelist') ||
          errorStr.contains('errno');

      await LogHelper.writeLog(
        "UI: Error - $errorStr",
        source: "log_view.dart",
        level: 1,
      );
      if (mounted) {
        setState(() {
          _isOffline = isNetworkError;
          _errorMessage = isNetworkError
              ? "Tidak dapat terhubung ke MongoDB Atlas.\nPeriksa koneksi internet."
              : "Terjadi kesalahan:\n$errorStr";
        });
      }
    } finally {
      // 2. INILAH FINALLY: // Apapun yang terjadi (Sukses/Gagal/Data Kosong), loading harus mati
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Logbook",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            Row(
              children: [
                Text(
                  "Halo, ${widget.username}!",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _controller.userRole,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: "Logout",
            onPressed: _handleLogout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari catatan...",
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.blueGrey,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1565C0),
                    width: 1.2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              onChanged: (value) => _controller.searchLog(value),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.filteredLogs,
              builder: (context, filteredLogs, child) {
                final currentLogs = _controller.logsNotifier.value;
                if (_isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Menghubungkan ke MongoDB Atlas..."),
                      ],
                    ),
                  );
                }

                if (_errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/no-internet.png',
                            width: 120,
                            height: 120,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _isOffline ? "Mode Offline" : "Koneksi Bermasalah",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF37474F),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blueGrey[500],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text("Coba Lagi"),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: _initDatabase,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(
                                Icons.cloud_off_rounded,
                                size: 18,
                              ),
                              label: const Text("Lanjut Offline"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blueGrey,
                                side: BorderSide(
                                  color: Colors.blueGrey.shade200,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () {
                                setState(() => _errorMessage = null);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 2. Tampilan jika loading sudah selesai tapi data di Atlas kosong
                if (filteredLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Belum ada catatan di Cloud.",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF455A64),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _goToEditor(),
                          child: const Text("Buat Catatan Pertama"),
                        ),
                      ],
                    ),
                  );
                }

                // Jika data sudah masuk, tampilkan List seperti biasa
                return RefreshIndicator(
                  color: const Color(0xFF1565C0),
                  onRefresh: _initDatabase,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 6, bottom: 80),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      final originalIndex = currentLogs.indexOf(log);
                      final color = _getCategoryColor(log.category);
                      final catIcon = _getCategoryIcon(log.category);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        child: Dismissible(
                          key: Key('${log.title}_$originalIndex'),
                          direction:
                              AccessControlService.canPerform(
                                _controller.userRole,
                                AccessControlService.actionDelete,
                                isOwner: log.authorId == _controller.username,
                              )
                              ? DismissDirection.endToStart
                              : DismissDirection.none,
                          secondaryBackground: Container(
                            decoration: BoxDecoration(
                              color: Colors.red[400],
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete_rounded,
                              color: Colors.white,
                            ),
                          ),
                          background: const SizedBox.shrink(),
                          onDismissed: (_) =>
                              _controller.removeLog(originalIndex),
                          child: Card(
                            margin: EdgeInsets.zero,
                            elevation: 3,
                            shadowColor: color.withValues(alpha: 0.25),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            color: Colors.white,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap:
                                  AccessControlService.canPerform(
                                    _controller.userRole,
                                    AccessControlService.actionUpdate,
                                    isOwner:
                                        log.authorId == _controller.username,
                                  )
                                  ? () => _goToEditor(
                                      index: originalIndex,
                                      log: log,
                                    )
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 14,
                                  top: 12,
                                  bottom: 12,
                                  right: 4,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  log.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                    color: Color(0xFF1A237E),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      catIcon,
                                                      size: 11,
                                                      color: color,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      log.category,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: color,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            log.description,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.blueGrey[600],
                                              height: 1.4,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                size: 11,
                                                color: Colors.blueGrey[300],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDate(
                                                  log.date.toString(),
                                                ),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blueGrey[300],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Tombol edit & hapus
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (AccessControlService.canPerform(_controller.userRole, AccessControlService.actionUpdate, isOwner: 
                                        log.authorId == _controller.username))
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit_outlined,
                                              color: Colors.blue[600],
                                              size: 18,
                                            ),
                                            onPressed: () => _goToEditor(
                                              index: originalIndex,
                                              log: log,
                                            ),
                                            tooltip: "Edit",
                                          visualDensity: VisualDensity.compact,
                                          ),
                                        if (AccessControlService.canPerform(_controller.userRole, AccessControlService.actionDelete, isOwner: 
                                        log.authorId == _controller.username))
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.red[400],
                                              size: 18,
                                            ),
                                            onPressed: () => _controller
                                                .removeLog(originalIndex),
                                            tooltip: "Hapus",
                                          visualDensity: VisualDensity.compact,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToEditor(), // Panggil fungsi navigasi page
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  String _formatDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) {
        return "Baru saja";
      } else if (diff.inMinutes < 60) {
        return "${diff.inMinutes} menit yang lalu";
      } else if (diff.inHours < 24) {
        return "${diff.inHours} jam yang lalu";
      } else if (diff.inDays < 2) {
        return "Kemarin, ${DateFormat('HH:mm').format(dt)}";
      }

      return DateFormat("d MMM yyyy, HH:mm", "id").format(dt);
    } catch (_) {
      return rawDate;
    }
  }
}
