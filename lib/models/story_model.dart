// lib/models/story_model.dart
class Story {
  final String id;
  final String userName;
  final String userImg;
  final String contentUrl; // Image or Video URL
  final DateTime createdAt;

  Story({required this.id, required this.userName, required this.userImg, 
         required this.contentUrl, required this.createdAt});
}