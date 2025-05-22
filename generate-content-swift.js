#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Path constants
const BASE_DIR = process.cwd(); // Current working directory
const ES_OUTPUT_DIR = path.join(BASE_DIR, 'seed', 'es', 'output');
const CONTENT_DIR = path.join(BASE_DIR, 'tong-ios', 'Content');
const TARGET_FILE = path.join(CONTENT_DIR, 'ESContent.swift');

// Read all JSON files from the output directory
function readJsonFiles() {
  const files = fs.readdirSync(ES_OUTPUT_DIR).filter(file => file.endsWith('.json'));
  console.log(`Found ${files.length} JSON files in output directory`);
  
  return files.map(file => {
    const filePath = path.join(ES_OUTPUT_DIR, file);
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      const parsed = JSON.parse(content);
      // Extract level code from filename (first 2 characters)
      const levelCode = file.substring(0, 2);
      return { levelCode, content: parsed };
    } catch (error) {
      console.error(`Error reading file ${filePath}:`, error);
      return null;
    }
  }).filter(Boolean);
}

// Group content by level code
function groupByLevel(jsonFiles) {
  const levels = {};
  
  jsonFiles.forEach(file => {
    if (!levels[file.levelCode]) {
      levels[file.levelCode] = [];
    }
    levels[file.levelCode].push(file.content);
  });
  
  return levels;
}

// Generate Swift code for a level
function generateLevelCode(levelCode, contents) {
  const topicsArray = contents.map(content => {
    return `
            _Topic(
                id: UUID(uuidString: "${content.topic_id || generateUUID(content.topic_slug)}")!,
                slug: "${content.topic_slug}",
                title: "${escapeString(content.topic_title)}",
                canDoStatement: "${escapeString(content.can_do_statement)}",
                levelCode: "${levelCode}",
                langCode: "es",
                lessons: [
${generateLessonsCode(content.lessons)}
                ]
            )`;
  }).join(',\n');
  
  return `
    // MARK: - ${levelCode} Level
    public enum ${levelCode} {
        // Convert content data to the app's model types
        public static func getTopics() -> [ContentModels.Topic] {
            return _topics.map { contentTopic in
                ContentModels.Topic(
                    id: contentTopic.id,
                    slug: contentTopic.slug,
                    title: contentTopic.title,
                    canDoStatement: contentTopic.canDoStatement,
                    levelCode: contentTopic.levelCode,
                    langCode: contentTopic.langCode,
                    lessons: contentTopic.lessons.map { contentLesson in
                        ContentModels.Lesson(
                            id: contentLesson.id,
                            slug: contentLesson.slug,
                            title: contentLesson.title,
                            objective: contentLesson.objective,
                            orderInTopic: contentLesson.orderInTopic,
                            content: contentLesson.content,
                            cards: contentLesson.cards.map { contentCard in
                                ContentModels.Card(
                                    id: contentCard.id,
                                    word: contentCard.word,
                                    translation: contentCard.translation,
                                    ipa: contentCard.ipa,
                                    audioURL: contentCard.audioURL,
                                    imageURL: contentCard.imageURL,
                                    exampleSentence: contentCard.exampleSentence,
                                    grammarExplanation: contentCard.grammarExplanation,
                                    orderInLesson: contentCard.orderInLesson
                                )
                            }
                        )
                    }
                )
            }
        }
        
        // Content data structure (private)
        private struct _Card {
            let id: UUID
            let word: String
            let translation: String
            let ipa: String?
            let audioURL: String?
            let imageURL: String?
            let exampleSentence: String
            let grammarExplanation: String?
            let orderInLesson: Int
        }
        
        private struct _Lesson {
            let id: UUID
            let slug: String
            let title: String
            let objective: String
            let orderInTopic: Int
            let content: String?
            let cards: [_Card]
        }
        
        private struct _Topic {
            let id: UUID
            let slug: String
            let title: String
            let canDoStatement: String
            let levelCode: String
            let langCode: String
            let lessons: [_Lesson]
        }
        
        // Private static data
        private static let _topics: [_Topic] = [
${topicsArray}
        ]
    }`;
}

// Generate lessons code
function generateLessonsCode(lessons) {
  return lessons.map((lesson, index) => {
    return `
                    _Lesson(
                        id: UUID(uuidString: "${lesson.id || generateUUID(lesson.slug)}")!,
                        slug: "${lesson.slug}",
                        title: "${escapeString(lesson.title)}",
                        objective: "${escapeString(lesson.objective)}",
                        orderInTopic: ${index},
                        content: ${lesson.content ? `"${escapeString(lesson.content)}"` : 'nil'},
                        cards: [
${generateCardsCode(lesson.cards)}
                        ]
                    )`;
  }).join(',\n');
}

// Generate cards code
function generateCardsCode(cards) {
  return cards.map((card, index) => {
    return `
                            _Card(
                                id: UUID(uuidString: "${card.id || generateUUID(card.front + index)}")!,
                                word: "${escapeString(card.front)}",
                                translation: "${escapeString(card.back)}",
                                ipa: ${card.ipa ? `"${escapeString(card.ipa)}"` : 'nil'},
                                audioURL: ${card.audio_url ? `"${escapeString(card.audio_url)}"` : 'nil'},
                                imageURL: ${card.image_url ? `"${escapeString(card.image_url)}"` : 'nil'},
                                exampleSentence: "${escapeString(card.example_sentence)}",
                                grammarExplanation: ${card.grammar_explanation ? `"${escapeString(card.grammar_explanation)}"` : 'nil'},
                                orderInLesson: ${index}
                            )`;
  }).join(',\n');
}

// Helper function to escape strings
function escapeString(str) {
  if (!str) return '';
  return str
    .replace(/\\/g, '\\\\')
    .replace(/"/g, '\\"')
    .replace(/\n/g, '\\n');
}

// Helper function to generate a deterministic UUID from a string
function generateUUID(input) {
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

// Main function
function main() {
  try {
    // Read JSON files
    const jsonFiles = readJsonFiles();
    if (jsonFiles.length === 0) {
      console.error('No JSON files found');
      process.exit(1);
    }
    
    // Group by level
    const levelGroups = groupByLevel(jsonFiles);
    
    // Generate Swift code for each level
    const levelCodes = Object.keys(levelGroups).sort();
    const levelCodeBlocks = levelCodes.map(levelCode => {
      return generateLevelCode(levelCode, levelGroups[levelCode]);
    });
    
    // Generate the complete Swift file
    const swiftCode = `// Generated Swift code for Spanish language content
// This file is auto-generated - do not edit directly

import Foundation

// MARK: - Spanish Content
public enum SpanishContent {
${levelCodeBlocks.join('\n')}
}`;
    
    // Write to file
    fs.writeFileSync(TARGET_FILE, swiftCode);
    console.log(`✅ Successfully generated Swift file: ${TARGET_FILE}`);
  } catch (error) {
    console.error('Error generating Swift code:', error);
    process.exit(1);
  }
}

// Run the script
main(); 