import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'player_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    final playerState = Provider.of<AppPlayerState>(context);
    final supabase = Supabase.instance.client;

   Future<void> _showAddToPlaylistDialog() async {
  try {
    // 1. Проверка авторизации
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Необходимо авторизоваться')),
        );
      }
      return;
    }

    // 3. Получаем ID трека из базы данных по URL
    final trackResponse = await supabase
        .from('tracks')
        .select('id')
        .eq('url', playerState.currentTrackUrl!)
        .maybeSingle();

    if (trackResponse == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Трек не найден в базе данных')),
        );
      }
      return;
    }

    final trackId = trackResponse['id'] as int;

    // 4. Получаем плейлисты пользователя
    final List<Map<String, dynamic>> playlists = [];
    try {
      final response = await supabase
          .from('list')
          .select('id, list_name, image')
          .eq('id_user', userId)
          .order('created_at', ascending: false);

      if (response != null) {
        playlists.addAll(List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка загрузки плейлистов')),
        );
      }
      return;
    }

    if (playlists.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('У вас пока нет плейлистов')),
        );
      }
      return;
    }

    // 5. Показываем диалог выбора плейлиста
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.blueGrey[800],
            title: Column(
              children: [
                const Text('Добавить в плейлист', 
                    style: TextStyle(color: Colors.white)),
                Text(
                  playerState.currentTrackTitle!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        playlist['image'] ?? 'https://via.placeholder.com/150'),
                    ),
                    title: Text(
                      playlist['list_name'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      try {
                        // Проверка существования трека в плейлисте
                        final existing = await supabase
                            .from('play_list')
                            .select()
                            .eq('list_id', playlist['id'])
                            .eq('track_id', trackId)
                            .maybeSingle();

                        if (existing != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Трек уже в плейлисте')),
                          );
                          return;
                        }

                        // Добавление трека
                        await supabase.from('play_list').insert({
                          'list_id': playlist['id'],
                          'track_id': trackId,
                          'created_at': DateTime.now().toIso8601String(),
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Трек добавлен!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка добавления: ${e.toString()}')),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    }
  }
}

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.blue[800],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (playerState.currentTrackUrl != null) ...[
            SizedBox(
              height: 4,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: (playerState.currentPosition?.inMilliseconds ?? 0).toDouble(),
                  max: (playerState.currentDuration?.inMilliseconds ?? 1).toDouble(),
                  onChanged: (value) {
                    playerState.seek(Duration(milliseconds: value.toInt()));
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(playerState.currentPosition ?? Duration.zero),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatDuration(playerState.currentDuration ?? Duration.zero),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  if (playerState.currentTrackImage != null)
                    Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        image: DecorationImage(
                          image: NetworkImage(playerState.currentTrackImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playerState.currentTrackTitle ?? 'Не выбрано',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          playerState.currentTrackAuthor ?? 'Нет трека',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.playlist_add, color: Colors.white, size: 24),
                        onPressed: _showAddToPlaylistDialog,
                        padding: const EdgeInsets.all(6),
                      ),
                      
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white, size: 26),
                        onPressed: playerState.previousTrack,
                        padding: const EdgeInsets.all(6),
                      ),
                      
                      Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            playerState.isPlaying 
                                ? Icons.pause_rounded 
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: playerState.togglePlayPause,
                        ),
                      ),
                      
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white, size: 26),
                        onPressed: playerState.nextTrack,
                        padding: const EdgeInsets.all(6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}