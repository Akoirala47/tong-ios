#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Supabase connection
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Error: SUPABASE_URL and SUPABASE_SERVICE_KEY must be defined in .env file');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

// Path constants
const BASE_DIR = process.cwd(); // Current working directory
const SEED_DIR = path.join(BASE_DIR, 'seed');
const LANGUAGES = ['es', 'fr', 'jp', 'zh']; // supported languages

// Main function to seed all content
async function seedAllContent() {
  try {
    console.log('Starting content seeding to Supabase...');
    
    // Process each language
    for (const lang of LANGUAGES) {
      const langDir = path.join(SEED_DIR, lang);
      
      // Skip if language directory doesn't exist
      if (!fs.existsSync(langDir)) {
        console.log(`Skipping ${lang} - directory doesn't exist`);
        continue;
      }
      
      console.log(`Processing ${lang} content...`);
      
      // Process the output directory for each language
      const outputDir = path.join(langDir, 'output');
      if (fs.existsSync(outputDir)) {
        await processOutputDirectory(outputDir, lang);
      } else {
        console.log(`No output directory found for ${lang}`);
      }
    }
    
    console.log('Content seeding completed successfully!');
  } catch (error) {
    console.error('Error seeding content:', error);
    process.exit(1);
  }
}

// Process all files in the output directory
async function processOutputDirectory(outputDir, langCode) {
  const files = fs.readdirSync(outputDir);
  
  for (const file of files) {
    if (file.endsWith('.json')) {
      const filePath = path.join(outputDir, file);
      const content = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      
      if (file === 'topics.json') {
        await processTopics(content, langCode);
      }
    }
  }
}

// Process topics and create them in Supabase
async function processTopics(topics, langCode) {
  console.log(`Processing ${topics.length} topics for ${langCode}...`);
  
  for (const topic of topics) {
    // First, insert the topic
    const { data: topicData, error: topicError } = await supabase
      .from('topics')
      .upsert({
        id: topic.id,
        title: topic.title,
        can_do_statement: topic.canDoStatement,
        level_code: topic.levelCode,
        lang_code: langCode,
        order_in_level: topic.orderInLevel
      })
      .select('id')
      .single();
    
    if (topicError) {
      console.error(`Error inserting topic ${topic.title}:`, topicError);
      continue;
    }
    
    const topicId = topicData.id;
    console.log(`Inserted/updated topic: ${topic.title} (${topicId})`);
    
    // Then, process lessons for this topic
    await processLessons(topic.lessons, topicId, langCode);
  }
}

// Process lessons and create them in Supabase
async function processLessons(lessons, topicId, langCode) {
  for (const lesson of lessons) {
    // Insert the lesson
    const { data: lessonData, error: lessonError } = await supabase
      .from('lessons')
      .upsert({
        id: lesson.id,
        title: lesson.title,
        content: lesson.content,
        topic_id: topicId,
        order_in_topic: lesson.orderInTopic
      })
      .select('id')
      .single();
    
    if (lessonError) {
      console.error(`Error inserting lesson ${lesson.title}:`, lessonError);
      continue;
    }
    
    const lessonId = lessonData.id;
    console.log(`  Inserted/updated lesson: ${lesson.title} (${lessonId})`);
    
    // Process flashcards for this lesson
    await processFlashcards(lesson.cards, lessonId);
  }
}

// Process flashcards and create them in Supabase
async function processFlashcards(cards, lessonId) {
  for (const card of cards) {
    // Insert the flashcard
    const { data: cardData, error: cardError } = await supabase
      .from('flashcards')
      .upsert({
        id: card.id,
        word: card.word,
        translation: card.translation,
        ipa: card.ipa || null,
        audio_url: card.audioURL || null,
        image_url: card.imageURL || null,
        example_sentence: card.exampleSentence || '',
        grammar_explanation: card.grammarExplanation || null,
        order_in_lesson: card.orderInLesson,
        lesson_id: lessonId
      })
      .select('id')
      .single();
    
    if (cardError) {
      console.error(`    Error inserting flashcard ${card.word}:`, cardError);
      continue;
    }
    
    console.log(`    Inserted/updated flashcard: ${card.word} (${cardData.id})`);
  }
}

// Start the seeding process
seedAllContent()
  .then(() => {
    console.log('Content seeding process completed.');
    process.exit(0);
  })
  .catch(error => {
    console.error('Unhandled error during seeding:', error);
    process.exit(1);
  }); 