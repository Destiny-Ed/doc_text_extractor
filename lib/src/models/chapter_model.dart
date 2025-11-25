class Chapter {
  final int id;
  final String title;
  final String content;
  final int startPage;
  final int endPage;

  const Chapter({
    required this.id,
    required this.title,
    required this.content,
    required this.startPage,
    required this.endPage,
  });

  int get pageCount => endPage - startPage + 1;

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
    id: json['id'] as int,
    title: json['title'] as String,
    content: json['content'] as String,
    startPage: json['startPage'] as int,
    endPage: json['endPage'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'startPage': startPage,
    'endPage': endPage,
  };
}
