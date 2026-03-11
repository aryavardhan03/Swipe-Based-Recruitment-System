class MatchingService {
  static final Set<String> candidateLikes = {};
  static final Set<String> employerLikes = {};

  static void candidateLike(String jobId) {
    candidateLikes.add(jobId);
  }

  static void employerLike(String candidateId) {
    employerLikes.add(candidateId);
  }

  static bool hasMutualMatch() {
    return candidateLikes.isNotEmpty && employerLikes.isNotEmpty;
  }

  static int getCompatibilityScore() {
    return 70 + (DateTime.now().second % 20); // 70–89%
  }
}


