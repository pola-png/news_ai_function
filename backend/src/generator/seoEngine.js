export const seoEngine = {
  optimizeContent: (body, primaryKeyword, keys = []) => {
    // Basic optimization rules: ensure primary keyword is present in body
    const keywordCount = (body.match(new RegExp(primaryKeyword, 'gi')) || []).length;
    let optimized = body;
    if (keywordCount < 2) {
      optimized = `${optimized}\n\nRelated: ${primaryKeyword}`;
    }
    
    // Inject/Append related SEO keys
    if (keys && keys.length > 0) {
      const distinctKeys = keys.filter(k => k.toLowerCase() !== primaryKeyword.toLowerCase());
      if (distinctKeys.length > 0) {
        optimized = `${optimized}\n\nSEO Keys: ${distinctKeys.join(', ')}`;
      }
    }
    return optimized;
  }
};
