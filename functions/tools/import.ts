import * as fs from 'fs';
import * as path from 'path';

// Get project root path (two levels up from this file)
const PROJECT_ROOT = path.resolve(path.join(__dirname, "../.."));

// Function to read all JSON files from the output directory
function readGeneratedContent(langCode: string): any[] {
  const outputDir = path.join(PROJECT_ROOT, "seed", langCode, "output");
  if (!fs.existsSync(outputDir)) {
    console.error(`No output directory found for ${langCode}`);
    return [];
  }
  
  const files = fs.readdirSync(outputDir).filter(file => file.endsWith('.json'));
  console.log(`Found ${files.length} generated content files for ${langCode}`);
  
  return files.map(file => {
    const filePath = path.join(outputDir, file);
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      return JSON.parse(content);
    } catch (error) {
      console.error(`Error reading file ${filePath}:`, error);
      return null;
    }
  }).filter(Boolean);
}

// Helper function to generate a deterministic UUID from a string
function generateUUID(input: string): string {
  // Create a simple hash from the input string
  let hash = 0;
  for (let i = 0; i < input.length; i++) {
    const char = input.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32bit integer
  }
  
  // Use the hash to create parts of the UUID
  const hashStr = Math.abs(hash).toString(16).padStart(8, '0');
  return `${hashStr.slice(0, 8)}-${hashStr.slice(0, 4)}-4${hashStr.slice(0, 3)}-8${hashStr.slice(0, 3)}-${Math.abs(hash * 2).toString(16).padStart(12, '0').slice(0, 12)}`;
}

// Function to convert content to a format ready for Swift JSON loading
function prepareContentForJson(langCode: string, lessonBatches: any[]): any {
  // Generate a language name with proper capitalization
  const langName = langCode === 'es' ? 'Spanish' : 
                  langCode === 'fr' ? 'French' : 
                  langCode === 'jp' ? 'Japanese' : 
                  langCode === 'zh' ? 'Chinese' : 
                  langCode.toUpperCase();
  
  // Group by level
  const levels: Record<string, any[]> = {};
  lessonBatches.forEach(batch => {
    if (!levels[batch.level_code]) {
      levels[batch.level_code] = [];
    }
    levels[batch.level_code].push(batch);
  });
  
  // Create the result structure
  const result: Record<string, Record<string, any[]>> = {
    [langName]: {}
  };
  
  // Process each level
  Object.keys(levels).sort().forEach(levelCode => {
    const batches = levels[levelCode];
    
    // Create the topics array for this level
    const topics = batches.map(batch => {
      // Transform lessons
      const lessons = batch.lessons.map((lesson: any, lessonIndex: number) => {
        // Transform cards
        const cards = lesson.cards.map((card: any, cardIndex: number) => ({
          id: generateUUID(batch.topic_slug + '-' + lesson.slug + '-' + cardIndex),
          word: card.front,
          translation: card.back,
          ipa: card.ipa || null,
          audioURL: card.audio_url || null,
          imageURL: card.image_url || null,
          exampleSentence: card.example_sentence,
          grammarExplanation: card.grammar_explanation || null,
          orderInLesson: cardIndex
        }));
        
        return {
          id: generateUUID(batch.topic_slug + '-' + lesson.slug),
          slug: lesson.slug,
          title: lesson.title,
          objective: lesson.objective,
          orderInTopic: lessonIndex,
          content: lesson.content || null,
          cards: cards
        };
      });
      
      return {
        id: generateUUID(batch.topic_slug),
        slug: batch.topic_slug,
        title: batch.topic_title,
        canDoStatement: batch.can_do_statement,
        levelCode: batch.level_code,
        langCode: langCode,
        lessons: lessons
      };
    });
    
    // Add topics to the result structure
    result[langName][levelCode] = topics;
  });
  
  return result;
}

// Main function
async function main() {
  const args = process.argv.slice(2);
  const langCode = args.find(arg => arg.startsWith('--lang='))?.split('=')[1] || 'es';
  
  console.log(`Importing content for language: ${langCode}`);
  
  // Read generated content
  const lessonBatches = readGeneratedContent(langCode);
  
  if (lessonBatches.length === 0) {
    console.error('No content found to import');
    process.exit(1);
  }
  
  // Generate data in JSON format
  const contentData = prepareContentForJson(langCode, lessonBatches);
  
  // Determine the output directory in the iOS project
  const iosContentDir = path.join(PROJECT_ROOT, 'tong-ios', 'Content');
  if (!fs.existsSync(iosContentDir)) {
    fs.mkdirSync(iosContentDir, { recursive: true });
  }
  
  // Write the JSON file
  const jsonFilePath = path.join(iosContentDir, `${langCode.toUpperCase()}Content.json`);
  fs.writeFileSync(jsonFilePath, JSON.stringify(contentData, null, 2));
  console.log(`✅ Successfully generated JSON file: ${jsonFilePath}`);
  
  console.log(`\nTo use this content in your app, use the ESContentLoader class to load and access the data.`);
  console.log(`Example usage:

// Get topics for a specific level
let topics = ESContentLoader.getTopics(levelCode: "NL")

// Get lessons for a topic
let lessons = ESContentLoader.getLessons(topicId: topics.first?.id ?? UUID())

// Get cards for a lesson
let cards = ESContentLoader.getCards(lessonId: lessons.first?.id ?? UUID())
`);
}

// Run if called directly
if (require.main === module) {
  main().catch(console.error);
}

export { readGeneratedContent, prepareContentForJson }; 