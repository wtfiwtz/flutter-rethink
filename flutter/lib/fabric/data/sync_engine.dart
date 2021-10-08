
// See https://github.com/firebase/firebase-js-sdk/blob/master/packages/firestore/src/core/sync_engine_impl.ts
// for the Firestore equivalent

class SyncEngine {
  Map<String,Map<String,Object>> caches;

  SyncEngine(): caches = <String,Map<String,Object>>{};

  Map<String,Object> buildCache(String path) {
    return caches.putIfAbsent(path, () => <String,Object>{});
  }

  void addToCache(Map<String,Object> cache, Map obj) {
    cache[obj['id']] = obj;
  }
}