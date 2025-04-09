import 'package:flutter/material.dart';

class HorizontalButtonList extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> itemsFuture;
  final Function(Map<String, dynamic>) onPressed;

  const HorizontalButtonList({super.key, required this.itemsFuture, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Ошибка загрузки данных'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Нет данных'));
        } else {
          final items = snapshot.data!;
          return SizedBox(
            height: 140,
            child: ListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => onPressed(item),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: item['Image'] != null
                              ? NetworkImage(item['Image'])
                              : null,
                          child: item['Image'] == null
                              ? Text(
                                  item['Name'][0],
                                  style: TextStyle(fontSize: 24, color: Colors.white),
                                )
                              : null,
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          width: 80,
                          child: Text(
                            item['Name'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }
      },
    );
  }
}