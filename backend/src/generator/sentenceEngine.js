export const sentenceEngine = {
  buildSentence: (subject, action, object) => {
    return `${subject} recently ${action} ${object}.`;
  }
};
