class SupportMessageModel {
  const SupportMessageModel({required this.id, required this.body, required this.senderId, required this.createdAt});
  final String id, body, senderId; final DateTime createdAt;
  factory SupportMessageModel.fromJson(Map<String,dynamic> j)=>SupportMessageModel(id: j['id']?.toString()??'',body:j['body']?.toString()??'',senderId:j['senderId']?.toString()??'',createdAt:DateTime.tryParse(j['createdAt']?.toString()??'')??DateTime.now());
}
class SupportTicketModel {
  const SupportTicketModel({required this.id,required this.category,required this.status,required this.updatedAt,required this.messages});
  final String id,category,status; final DateTime updatedAt; final List<SupportMessageModel> messages;
  factory SupportTicketModel.fromJson(Map<String,dynamic> j)=>SupportTicketModel(id:j['id']?.toString()??'',category:j['category']?.toString()??'GENERAL',status:j['status']?.toString()??'OPEN',updatedAt:DateTime.tryParse(j['updatedAt']?.toString()??'')??DateTime.now(),messages:((j['messages'] as List?)??const []).whereType<Map>().map((m)=>SupportMessageModel.fromJson(Map<String,dynamic>.from(m))).toList());
}