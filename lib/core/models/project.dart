enum ProjectKind { vanilla, sass, node }

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.rootPath,
    this.kind = ProjectKind.vanilla,
    this.entryFile = 'index.html',
  });

  final String id;
  final String name;
  final String rootPath;
  final ProjectKind kind;
  final String entryFile;
}
