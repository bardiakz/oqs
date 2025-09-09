//Cryptographically Secure Random Generation

import 'package:oqs/oqs.dart';

void main() {
  // Generate random bytes
  final randomBytes = OQSRandom.generateBytes(32);
  print('Random bytes: ${randomBytes.take(8).toList()}...');

  // Generate a cryptographic seed
  final seed = OQSRandom.generateSeed(); // Default 32 bytes
  print('Seed: ${seed.take(8).toList()}...');

  // Generate random integers
  final randomInt = OQSRandom.generateInt(1, 100);
  print('Random integer (1-99): $randomInt');

  // Generate random boolean
  final randomBool = OQSRandomExtensions.generateBool();
  print('Random boolean: $randomBool');

  // Generate random double (0.0 to 1.0)
  final randomDouble = OQSRandomExtensions.generateDouble();
  print('Random double: $randomDouble');

  // Cryptographically secure shuffle
  final list = [1, 2, 3, 4, 5];
  OQSRandomExtensions.shuffleList(list);
  print('Shuffled list: $list');

  // Switch RNG algorithm (advanced)
  print('Available RNG algorithms: ${OQSRandom.getAvailableAlgorithms()}');
  final switched = OQSRandom.switchAlgorithm('system');
  print('Switched to system RNG: $switched');
}
