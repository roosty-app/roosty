import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'item.dart';
import 'pipeline.dart';

final pipelineProvider = Provider<Pipeline>((ref) => const Pipeline());

final historyProvider = Provider<List<Item>>((ref) => const []);
