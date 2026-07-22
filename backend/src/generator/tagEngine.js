export const tagEngine = {
  generateTags: (title, category) => {
    const rawTags = title.toLowerCase().split(/\s+/).filter(word => word.length > 4);
    if (category) rawTags.push(category.toLowerCase());
    return [...new Set(rawTags)];
  }
};
