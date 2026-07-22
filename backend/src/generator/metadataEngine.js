export const metadataEngine = {
  buildMetadata: (title, description, slug) => {
    return {
      title,
      description,
      openGraph: {
        title,
        description,
        type: 'article',
        url: `https://xapzap.com/news/${slug}`
      },
      twitter: {
        card: 'summary_large_image',
        title,
        description
      }
    };
  }
};
