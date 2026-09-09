import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_video_player/flutter_video_player.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPTV Player',
      home: const TvPlayerPage(),
    );
  }
}

class TvPlayerPage extends StatefulWidget {
  const TvPlayerPage({super.key});

  @override
  State<TvPlayerPage> createState() => _TvPlayerPageState();
}

class _TvPlayerPageState extends State<TvPlayerPage> {
  List<TvChannel> _channels = [];
  TvChannel? _selectedChannel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    final resp = await http.get(
      Uri.parse('https://live.zbds.top/tv/iptv4.m3u'),
      headers: {
        'Accept-Encoding': 'identity',  // 禁用压缩，避免乱码
      },
    );
    if (resp.statusCode == 200) {
      // 尝试用UTF-8解码，如果失败则用latin1
      String body;
      try {
        body = utf8.decode(resp.bodyBytes);
      } catch (_) {
        body = latin1.decode(resp.bodyBytes);
      }
      _channels = _parseM3u(body);
      if (_channels.isNotEmpty) {
        _selectedChannel = _channels.first;
      }
    }
    setState(() => _isLoading = false);
  }

  List<TvChannel> _parseM3u(String content) {
    final lines = content.split('\n');
    final channels = <TvChannel>[];
    String? name, logo, group;
    String? url;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('#EXTINF:')) {
        name = _getAttribute(trimmed, 'tvg-name');
        if (name == null) {
          // 名称在逗号后面
          final commaIdx = trimmed.lastIndexOf(',');
          if (commaIdx >= 0) {
            name = trimmed.substring(commaIdx + 1).trim();
          }
        }
        logo = _getAttribute(trimmed, 'tvg-logo');
        group = _getAttribute(trimmed, 'group-title');
      } else if (!trimmed.startsWith('#')) {
        url = trimmed;
        if (name != null && url != null) {
          channels.add(TvChannel(
            name: name,
            url: url,
            logo: logo,
            group: group ?? '未分类',
          ));
          name = null;
          logo = null;
          group = null;
          url = null;
        }
      }
    }
    return channels;
  }

  String? _getAttribute(String line, String attr) {
    final reg = RegExp('$attr="([^"]*)"');
    final match = reg.firstMatch(line);
    return match?.group(1);
  }

  Map<String, List<TvChannel>> get _groupedChannels {
    final map = <String, List<TvChannel>>{};
    for (final ch in _channels) {
      map.putIfAbsent(ch.group, () => []).add(ch);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // 左侧频道列表
                SizedBox(
                  width: 200,
                  child: _buildChannelList(),
                ),
                // 右侧播放器
                Expanded(
                  child: _selectedChannel == null
                      ? const Center(child: Text('请选择频道'))
                      : VideoPlayerWidget(
                          controller: VideoPlayController(_selectedChannel!.url),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildChannelList() {
    final grouped = _groupedChannels;
    final groups = grouped.keys.toList()..sort();

    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (ctx, i) {
        final group = groups[i];
        final channels = grouped[group]!;
        return ExpansionTile(
          title: Text(group),
          children: channels.map((ch) {
            final selected = _selectedChannel == ch;
            return ListTile(
              leading: ch.logo != null
                  ? Image.network(ch.logo!, width: 30, height: 30, errorBuilder: (_, __, ___) => const Icon(Icons.tv))
                  : const Icon(Icons.tv),
              title: Text(ch.name, style: TextStyle(
                color: selected ? Colors.blue : null,
                fontWeight: selected ? FontWeight.bold : null,
              )),
              selected: selected,
              onTap: () => setState(() => _selectedChannel = ch),
            );
          }).toList(),
        );
      },
    );
  }
}

class TvChannel {
  final String name;
  final String url;
  final String? logo;
  final String group;

  TvChannel({
    required this.name,
    required this.url,
    this.logo,
    required this.group,
  });
}
