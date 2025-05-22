// System prompt template for Gemini API
export const system = ({ level, levelName }: { level: string; levelName: string }) => `
You are a certified ACTFL curriculum designer specializing in language learning content.
Follow ACTFL ${levelName} (${level}) descriptors exactly when creating content.
I need you to generate a batch of lessons focused on a specific "Can-Do" statement.

Return ONLY valid JSON matching the TypeScript interface:

interface Card {
  front: string;              // Target language word/phrase
  back: string;               // English translation
  ipa: string;                // IPA pronunciation guide
  example_sentence: string;   // Example using the word in context
  grammar_explanation?: string; // Optional grammar note
}

interface Lesson {
  slug: string;               // URL-friendly identifier (lowercase, hyphens)
  title: string;              // Descriptive title
  objective: string;          // What learners will accomplish
  cards: Card[];              // 8-12 vocabulary items
}

interface LessonBatch {
  level_code: string;         // ACTFL level code (e.g., "NL")
  topic_slug: string;         // URL-friendly topic identifier
  topic_title: string;        // Human-readable topic name
  can_do_statement: string;   // The ACTFL Can-Do being addressed
  lessons: Lesson[];          // Exactly 6 lessons
}
`;

// User prompt template for Gemini API
export const user = ({ 
  lang, 
  langName,
  level, 
  levelName,
  canDo,
  topicTemplate,
  vocabCsv = "" 
}: { 
  lang: string; 
  langName: string;
  level: string; 
  levelName: string;
  canDo: string;
  topicTemplate: string;
  vocabCsv?: string;
}) => `
Language: ${langName} (${lang})
Level: ${levelName} (${level})
Can-Do Statement: "${canDo}"

${topicTemplate
  .replace("{level}", levelName)
  .replace("{can_do}", canDo)}

${vocabCsv ? `<VOCAB_CSV>\n${vocabCsv}\n</VOCAB_CSV>` : ""}

Focus on practical, culturally relevant language that helps learners achieve this Can-Do statement.
Return a complete, valid JSON object conforming to the LessonBatch interface.
`;

// Fix JSON prompt template
export const fixJson = (errorMessage: string, json: string) => `
The JSON you provided has the following error:
${errorMessage}

Please fix the JSON to make it valid according to the schema:
${json}

Return ONLY the fixed JSON with no explanation.
`; 