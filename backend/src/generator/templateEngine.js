export const templateEngine = {
  getTemplateLayout: (contentType) => {
    switch (contentType) {
      case 'listicle':
        return ['Introduction', 'Top Highlights List', 'Detailed Items', 'Final Summary'];
      case 'how_to':
        return ['Introduction', 'Prerequisites', 'Step-by-Step Instructions', 'FAQs', 'Conclusion'];
      case 'breaking_news':
      default:
        return ['Headline Lead', 'Core Facts', 'Context & Background', 'Quotes', 'Future Outlook'];
    }
  }
};
