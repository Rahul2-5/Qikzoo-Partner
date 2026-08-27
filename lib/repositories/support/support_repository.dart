import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../models/support/support_models.dart';
class SupportRepository {
  const SupportRepository(this.api); final ApiClient api;
  Map<String,dynamic> unwrap(dynamic v)=>v is Map<String,dynamic> && v['data'] is Map<String,dynamic> ? v['data'] as Map<String,dynamic> : Map<String,dynamic>.from(v as Map);
  Future<List<SupportTicketModel>> list() async { final r=await api.get(ApiEndpoints.riderSupportTickets); final d=r.data; final raw=d is Map && d['data'] is List ? d['data'] as List : (d as List? ?? const []); return raw.whereType<Map>().map((x)=>SupportTicketModel.fromJson(Map<String,dynamic>.from(x))).toList(); }
  Future<SupportTicketModel> get(String id) async { final r=await api.get(ApiEndpoints.riderSupportTicket(id)); return SupportTicketModel.fromJson(unwrap(r.data)); }
  Future<SupportTicketModel> create(String category,String message) async { final r=await api.post(ApiEndpoints.riderSupportTickets,data:{'category':category,'message':message}); return SupportTicketModel.fromJson(unwrap(r.data)); }
  Future<SupportTicketModel> send(String id,String body) async { final r=await api.post(ApiEndpoints.riderSupportTicketMessages(id),data:{'body':body}); return SupportTicketModel.fromJson(unwrap(r.data)); }
}