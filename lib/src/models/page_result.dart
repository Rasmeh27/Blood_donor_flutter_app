// Corresponde a PageResponse<T> del backend
class PageResult<T> {
  final List<T> items;
  final int page;
  final int totalElements;
  final int totalPages;

  const PageResult({
    required this.items,
    required this.page,
    required this.totalElements,
    required this.totalPages,
  });

  bool get hasMore => page + 1 < totalPages;

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    return PageResult(
      items: (json['content'] as List<dynamic>)
          .map((item) => itemFromJson(item as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
