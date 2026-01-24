class EmojiList {
  static const List<String> assets = [
    'angry.jpeg',
    'big.jpeg',
    'bye.jpeg',
    'confuse.jpeg',
    'confused.jpeg',
    'cool.jpeg',
    'crazy.jpeg',
    'eating.jpeg',
    'glad.jpeg',
    'happy.jpeg',
    'happyed.jpeg',
    'hunger.jpeg',
    'hungery.jpeg',
    'i dont care.jpeg',
    'kiss.jpeg',
    'relife.jpeg',
    'sad.jpeg',
    'tired.jpeg',
    'uncertin.jpeg',
    'unknown.jpeg',
    'very happy.jpeg',
    'you.jpeg',
  ];

  static String getPath(String filename) {
    return 'assets/emojis/$filename';
  }
}
