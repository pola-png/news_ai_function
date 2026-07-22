export const schemaEngine = {
  buildArticleSchema: ({ title, summary, url, imageUrl, datePublished }) => {
    return {
      '@context': 'https://schema.org',
      '@type': 'NewsArticle',
      'headline': title,
      'description': summary,
      'image': [imageUrl],
      'datePublished': datePublished,
      'dateModified': datePublished,
      'mainEntityOfPage': url
    };
  }
};
