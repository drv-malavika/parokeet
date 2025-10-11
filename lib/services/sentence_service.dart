import 'package:parokeet/main.dart'; // Import to get the 'supabase' client instance

class SentenceService {
  /// Fetches a batch of quotes for a given category from Supabase,
  /// excluding any IDs that have already been fetched.
  static Future<List<Map<String, dynamic>>> getQuotesForCategory({
    required String category,
    required List<int> excludedIds,
    int limit = 100, // Fetch a large batch at once
  }) async {
    try {
      // 1. Find the category ID from the category name.
      final categoryResponse = await supabase
          .from('categories')
          .select('id')
          .eq('name', category)
          .single(); // Use .single() to get one record

      final categoryId = categoryResponse['id'];

      // 2. Fetch quotes for that category, excluding already seen ones.
      // We use a stored procedure for better performance and randomness on the server.
      final response = await supabase.rpc(
        'get_random_quotes',
        params: {
          'p_category_id': categoryId,
          'p_excluded_ids': excludedIds,
          'p_limit': limit,
        },
      );

      // The RPC returns a list of objects, which is what we need.
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching from Supabase: $e');
      // Return an empty list in case of any error.
      return [];
    }
  }
}
