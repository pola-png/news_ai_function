const store = new Map();

export const cache = {
  get: (key) => store.get(key),
  set: (key, value, ttlSeconds = 300) => {
    store.set(key, value);
    setTimeout(() => store.delete(key), ttlSeconds * 1000);
  },
  delete: (key) => store.delete(key),
  clear: () => store.clear()
};
