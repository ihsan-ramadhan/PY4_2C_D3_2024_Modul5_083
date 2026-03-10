import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;
import 'package:hive/hive.dart';
import './models/log_model.dart';
import 'package:logbook_app_083/services/mongo_service.dart';
import 'package:logbook_app_083/services/access_control_service.dart';
import 'package:logbook_app_083/helpers/log_helper.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);

  ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);

  // Kunci unik untuk penyimpanan lokal di Shared Preferences & Box name for Hive
  static const String _storageKey = 'offline_logs';
  late final Box<LogModel> _myBox;

  final Connectivity _connectivity = Connectivity();

  // Getter untuk mempermudah akses list data saat ini
  List<LogModel> get logs => logsNotifier.value;

  // --- BARU: KONSTRUKTOR ---
  final String username;
  final String userRole;
  final String teamId;

  // Saat Controller dibuat, ia otomatis mencoba mengambil data lama
  LogController({
    required this.username,
    required this.userRole,
    this.teamId = 'Team_01',
  }) {
    _myBox = Hive.box<LogModel>(_storageKey);
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      if (results.contains(ConnectivityResult.none)) return;

      if (logsNotifier.value.isEmpty) return;

      await LogHelper.writeLog(
        "SYNC: Internet terhubung, memulai cek data pending...",
        source: "log_controller.dart",
        level: 2,
      );

      await _syncPendingData();
    });
  }

  Future<void> _syncPendingData() async {
    try {
      final offlineData = _myBox.values.toList();

      final cloudData = await MongoService().getLogs(teamId);
      final cloudIds = cloudData.map((e) => e.id).toSet();

      bool hasSynced = false;

      for (var localLog in offlineData) {
        if (!cloudIds.contains(localLog.id)) {
          await LogHelper.writeLog(
            "SYNC: Data pending ditemukan -> ${localLog.title}. Mengirim ke Cloud...",
            source: "log_controller.dart",
            level: 2,
          );

          try {
            await MongoService().insertLog(localLog);
            hasSynced = true;
          } catch (e) {
            await LogHelper.writeLog(
              "SYNC ERROR: Gagal push data pending - $e",
              source: "log_controller.dart",
              level: 1,
            );
          }
        }
      }

      if (hasSynced) {
        await loadFromDisk();
      } else {
        await LogHelper.writeLog(
          "SYNC: Tidak ada data pending yang perlu disinkronkan.",
          source: "log_controller.dart",
          level: 3,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "SYNC ERROR: Sinkronisasi Latar Belakang Gagal - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogs.value = logsNotifier.value;
    } else {
      filteredLogs.value = logsNotifier.value
          .where((log) => log.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  // 1. Menambah data ke Cloud
  // 1. Menambah data (Instan Lokal + Background Cloud)
  Future<void> addLog(String title, String desc, String category) async {
    if (!AccessControlService.canPerform(
      userRole,
      AccessControlService.actionCreate,
    )) {
      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized create attempt",
        level: 1,
      );
      return;
    }

    final newLog = LogModel(
      id: ObjectId().oid, // Menggunakan .oid (String) untuk Hive
      title: title,
      description: desc,
      category: category,
      date: DateTime.now().toIso8601String(),
      authorId: username,
      teamId: teamId,
    );

    // ACTION 1: Simpan ke Hive (Instan)
    await _myBox.add(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];
    filteredLogs.value = logsNotifier.value;

    // ACTION 2: Kirim ke MongoDB Atlas (Background)
    try {
      await MongoService().insertLog(newLog);
      await LogHelper.writeLog(
        "SUCCESS: Data '${newLog.title}' tersinkron ke Cloud",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Data '${newLog.title}' tersimpan lokal, akan sinkron saat online - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // 2. Memperbarui data di Cloud (HOTS: Sinkronisasi Terjamin)
  // 2. Memperbarui data (Instan Lokal + Background Cloud)
  Future<void> updateLog(
    int index,
    String title,
    String desc,
    String category,
  ) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final oldLog = currentLogs[index];

    if (!AccessControlService.canPerform(
      userRole,
      AccessControlService.actionUpdate,
      isOwner: oldLog.authorId == username,
    )) {
      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized update attempt",
        level: 1,
      );
      return; // Hentikan proses jika tidak punya izin
    }

    final updatedLog = LogModel(
      id: oldLog.id, // ID harus tetap sama
      title: title,
      description: desc,
      category: category,
      date: DateTime.now().toIso8601String(),
      authorId: oldLog.authorId,
      teamId: oldLog.teamId,
    );

    // ACTION 1: Update ke Hive (Instan)
    await _myBox.putAt(index, updatedLog);
    currentLogs[index] = updatedLog;
    logsNotifier.value = currentLogs;
    filteredLogs.value = logsNotifier.value;

    // ACTION 2: Update ke MongoDB Atlas (Background)
    try {
      await MongoService().updateLog(updatedLog);
      await LogHelper.writeLog(
        "SUCCESS: Update '${oldLog.title}' tersinkron ke Cloud",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Update '${oldLog.title}' tersimpan lokal, akan sinkron saat online - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // 3. Menghapus data dari Cloud (HOTS: Sinkronisasi Terjamin)
  // 3. Menghapus data (Instan Lokal + Background Cloud)
  Future<void> removeLog(int index) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final targetLog = currentLogs[index];

    if (!AccessControlService.canPerform(
      userRole,
      AccessControlService.actionDelete,
      isOwner: targetLog.authorId == username,
    )) {
      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized delete attempt",
        level: 1,
      );
      return;
    }

    // ACTION 1: Hapus dari Hive (Instan)
    await _myBox.deleteAt(index);
    currentLogs.removeAt(index);
    logsNotifier.value = currentLogs;
    filteredLogs.value = logsNotifier.value;

    // ACTION 2: Hapus dari MongoDB (Background)
    try {
      if (targetLog.id != null) {
        await MongoService().deleteLog(ObjectId.fromHexString(targetLog.id!));
        await LogHelper.writeLog(
          "SUCCESS: Hapus '${targetLog.title}' tersinkron ke Cloud",
          source: "log_controller.dart",
          level: 2,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Gagal hapus di Cloud, mungkin butuh sinkronisasi manual - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // --- BARU: FUNGSI PERSISTENCE (SINKRONISASI JSON & HIVE) ---

  // LOAD DATA DARI HIVE KEMUDIAN SINKRONISASI KE CLOUD
  Future<void> loadFromDisk() async {
    // 1. Ambil data dari Hive (Offline-First)
    final localData = _myBox.values.toList();
    logsNotifier.value = localData;
    filteredLogs.value = localData;

    try {
      // 2. Fetch data team ini dari cloud
      final cloudData = await MongoService().getLogs(teamId);

      // SINKRONISASI: Replace Hive content with fresher Cloud content
      await _myBox.clear();
      await _myBox.addAll(cloudData);

      logsNotifier.value = cloudData;
      filteredLogs.value = cloudData;

      await LogHelper.writeLog(
        "SYNC: Data berhasil diperbarui dari Atlas untuk team $teamId",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "OFFLINE: Gagal menjangkau Cloud, menggunakan data cache lokal.",
        source: "log_controller.dart",
        level: 2,
      );
    }
  }
}
