import 'package:dio/dio.dart';
import '../models/models.dart';
import 'auth_service.dart';
import 'base_api_service.dart';

class VakinhaApiService extends BaseApiService {
  VakinhaApiService(AuthService authService) : super(authService);

  /// Busca todas as vakinhas com status "open"
  Future<List<Vakinha>> getOpenVakinhas() async {
    try {
      final response = await dio.get('/vakinhas/open');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        // O modelo VakinhaPublic do backend não tem a lista de contribuições
        // para manter a lista leve. Usamos o Vakinha.fromJson que
        // vai tratar a lista de contribuições como vazia.
        return data.map((json) => Vakinha.fromJson(json)).toList();
      }
      throw Exception('Falha ao carregar vakinhas abertas');
    } catch (e) {
      throw _handleError(e, 'carregar vakinhas');
    }
  }

  /// Busca os detalhes de UMA vakinha, incluindo as contribuições
  Future<Vakinha> getVakinhaDetails(int id) async {
    try {
      final response = await dio.get('/vakinhas/$id');
      if (response.statusCode == 200) {
        // O modelo VakinhaPublic deste endpoint já vem com a lista
        // de contribuições e usuários aninhada.
        return Vakinha.fromJson(response.data);
      }
      throw Exception('Falha ao carregar detalhes da vakinha');
    } catch (e) {
      throw _handleError(e, 'carregar detalhes da vakinha');
    }
  }

  /// Cria uma nova vakinha (somente admin)
  Future<Vakinha> createVakinha(VakinhaCreate vakinha) async {
    try {
      final response = await dio.post('/vakinhas/', data: vakinha.toJson());
      if (response.statusCode == 201) {
        return Vakinha.fromJson(response.data);
      }
      throw Exception('Falha ao criar vakinha');
    } catch (e) {
      throw _handleError(e, 'criar vakinha');
    }
  }

  /// Fecha uma vakinha (somente admin)
  Future<Vakinha> closeVakinha(int id, VakinhaClose closeData) async {
    try {
      final response = await dio.put('/vakinhas/$id/close', data: closeData.toJson());
      if (response.statusCode == 200) {
        return Vakinha.fromJson(response.data);
      }
      throw Exception('Falha ao fechar vakinha');
    } catch (e) {
      throw _handleError(e, 'fechar vakinha');
    }
  }

  /// Adiciona uma contribuição a uma vakinha
  Future<Contribution> addContribution(int vakinhaId, ContributionCreate contribution) async {
    try {
      final response = await dio.post(
        '/vakinhas/$vakinhaId/contribute', 
        data: contribution.toJson()
      );
      if (response.statusCode == 201) {
        return Contribution.fromJson(response.data);
      }
      throw Exception('Falha ao adicionar contribuição');
    } catch (e) {
      throw _handleError(e, 'adicionar contribuição');
    }
  }

  /// Helper para tratar erros do Dio
  Exception _handleError(Object e, String action) {
     if (e is DioException) {
      if (e.response?.statusCode == 403) {
        return Exception('Acesso negado para $action.');
      }
      if (e.response?.data['detail'] != null) {
        return Exception('Erro ao $action: ${e.response!.data['detail']}');
      }
      return Exception('Erro de rede ao $action: ${e.message}');
    }
    return Exception('Erro desconhecido ao $action: $e');
  }
}