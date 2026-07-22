export const synonymEngine = {
  replaceSynonyms: (text) => {
    // Simple word variations mapping
    return text.replace(/\b(fast)\b/gi, 'rapid').replace(/\b(smart)\b/gi, 'intelligent');
  }
};
