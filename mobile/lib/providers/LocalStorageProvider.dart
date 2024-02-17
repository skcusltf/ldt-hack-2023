import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lodt_hack/models/chat/Chat.dart';

import '../models/User.dart';
import '../models/consultation/ConsultationHolder.dart';

class LocalStorageProvider {
  final storage = const FlutterSecureStorage();

  Future<String?> getToken() {
    return storage.read(key: "token");
  }

  void saveToken(String token) {
    storage.write(key: "token", value: token);
  }

  Future<User?> getUser() async {
    final user = await storage.read(key: "user");

    if (user == null) {
      return null;
    }

    return User.fromJson(jsonDecode(user));
  }

  void saveUser(User user) {
    storage.write(key: "user", value: jsonEncode(user.toJson()));
  }

  Future<ChatHolder> getChat() async {
    final chat = await storage.read(key: "chat");

    if (chat == null) {
      return ChatHolder([]);
    }

    return ChatHolder.fromJson(jsonDecode(chat));
  }

  void saveChat(ChatHolder chat) async {
    storage.write(
      key: "chat",
      value: jsonEncode(
        chat.toJson(),
      ),
    );
  }

  Future<ConsultationHolder> getConsultations() async {
    final consultations = await storage.read(key: "consultations");

    if (consultations == null) {
      return ConsultationHolder([]);
    }

    return ConsultationHolder.fromJson(jsonDecode(consultations));
  }

  void saveConsultations(ConsultationHolder consultations) async {
    storage.write(
      key: "consultations",
      value: jsonEncode(
        consultations.toJson(),
      ),
    );
  }

  void clearData() {
    storage.deleteAll();
  }
}

final storageProvider = LocalStorageProvider();
