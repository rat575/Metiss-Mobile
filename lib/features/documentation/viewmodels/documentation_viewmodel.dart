import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document_model.dart';
import '../repositories/documentation_repository.dart';
import '../repositories/documentation_repository_provider.dart';

class DocumentationState {
  final List<DocumentRecord> documents;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? uploadError;
  final int page;
  final int total;
  final int perPage;
  final String searchQuery;
  final String sortBy;
  final String sortOrder;
  final bool uploadSuccess;

  DocumentationState({
    this.documents = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.uploadError,
    this.page = 1,
    this.total = 0,
    this.perPage = 10,
    this.searchQuery = '',
    this.sortBy = 'documentType',
    this.sortOrder = 'desc',
    this.uploadSuccess = false,
  });

  DocumentationState copyWith({
    List<DocumentRecord>? documents,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? uploadError,
    int? page,
    int? total,
    int? perPage,
    String? searchQuery,
    String? sortBy,
    String? sortOrder,
    bool? uploadSuccess,
  }) {
    return DocumentationState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      uploadError: uploadError,
      page: page ?? this.page,
      total: total ?? this.total,
      perPage: perPage ?? this.perPage,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      uploadSuccess: uploadSuccess ?? this.uploadSuccess,
    );
  }
}

class DocumentationNotifier extends StateNotifier<DocumentationState> {
  final DocumentationRepository _repository;

  DocumentationNotifier(this._repository) : super(DocumentationState());

  Future<void> fetchDocuments({bool resetPage = false}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      page: resetPage ? 1 : state.page,
    );

    try {
      final response = await _repository.getDocuments(
        page: state.page,
        perPage: state.perPage,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
        search: state.searchQuery,
      );

      state = state.copyWith(
        documents: response.documents,
        total: response.total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query, page: 1);
    fetchDocuments();
  }

  void setPage(int page) {
    if (state.page == page) return;
    state = state.copyWith(page: page);
    fetchDocuments();
  }

  void setSort(String field, String order) {
    state = state.copyWith(sortBy: field, sortOrder: order, page: 1);
    fetchDocuments();
  }

  Future<bool> createDocument({
    required DateTime executedDate,
    required DateTime effectiveDate,
    required String documentType,
    required String serviceName,
    required String status,
    required String term,
    required File file,
  }) async {
    state = state.copyWith(isSaving: true, uploadError: null, uploadSuccess: false);
    try {
      await _repository.createDocument(
        executedDate: executedDate,
        effectiveDate: effectiveDate,
        documentType: documentType,
        serviceName: serviceName,
        status: status,
        term: term,
        file: file,
      );
      state = state.copyWith(isSaving: false, uploadSuccess: true);
      // Refresh documents
      await fetchDocuments(resetPage: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        uploadSuccess: false,
        uploadError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void resetUploadState() {
    state = state.copyWith(uploadSuccess: false, uploadError: null);
  }
}

final documentationProvider =
    StateNotifierProvider<DocumentationNotifier, DocumentationState>((ref) {
  final repository = ref.watch(documentationRepositoryProvider);
  final notifier = DocumentationNotifier(repository);
  // Fetch documents initially
  Future.microtask(() => notifier.fetchDocuments());
  return notifier;
});
