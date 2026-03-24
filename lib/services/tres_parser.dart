class ParsedResource {
  final String resourceType;
  final String? name;
  final String? tooltip;
  final Map<String, String> properties;
  final List<Map<String, String>> subResources;
  final String rawText;

  ParsedResource({
    required this.resourceType,
    this.name,
    this.tooltip,
    required this.properties,
    required this.subResources,
    required this.rawText,
  });

  @override
  String toString() {
    return 'Type: $resourceType\nName: $name\nTooltip: $tooltip\nProperties: $properties\nSub-Resources: $subResources';
  }
}

class TresParser {
  static ParsedResource parse(String content) {
    String resourceType = 'Unknown';
    String? name;
    String? tooltip;
    Map<String, String> properties = {};
    List<Map<String, String>> subResources = [];

    final lines = content.split('\n');
    Map<String, String>? currentSection;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Handle section headers
      if (line.startsWith('[') && line.endsWith(']')) {
        final header = line.substring(1, line.length - 1);
        if (header.contains('gd_resource') || header == 'resource') {
          final typeMatch = RegExp(
            r'script_class="([^"]+)"',
          ).firstMatch(header);
          if (typeMatch != null) {
            resourceType = typeMatch.group(1)!;
          }
          currentSection = properties;
        } else if (header.contains('sub_resource')) {
          final subRes = <String, String>{};
          subResources.add(subRes);
          currentSection = subRes;
        } else {
          currentSection = null; // Other sections like ext_resource
        }
        continue;
      }

      // Handle key-value pairs
      if (currentSection != null && line.contains('=')) {
        final parts = line.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join('=').trim().replaceAll('"', '');
          currentSection[key] = value;

          if (key == 'name') name = value;
          if (key == 'tooltip') tooltip = value;
        }
      }
    }

    return ParsedResource(
      resourceType: resourceType,
      name: name,
      tooltip: tooltip,
      properties: properties,
      subResources: subResources,
      rawText: content,
    );
  }
}
