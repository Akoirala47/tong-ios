#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Supabase connection
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Error: SUPABASE_URL and SUPABASE_ANON_KEY must be defined in .env file');
  process.exit(1);
}

console.log('Connecting to Supabase:', supabaseUrl);
const supabase = createClient(supabaseUrl, supabaseKey);

// Path constants
const BASE_DIR = process.cwd();
const SPANISH_OUTPUT_DIR = path.join(BASE_DIR, 'seed', 'es', 'output');
const LANGUAGE_CODE = 'es';

// Utility to get language name
function getLanguageName(code) {
  const languages = {
    'es': 'Spanish',
    'fr': 'French',
    'ja': 'Japanese',
    'zh': 'Chinese',
    'de': 'German',
    'it': 'Italian',
    'ru': 'Russian',
    'pt': 'Portuguese',
    'ko': 'Korean',
    'ar': 'Arabic'
  };
  return languages[code] || code;
}

// Get or create language
async function getOrCreateLanguage(code) {
  try {
    // Check if language exists
    const { data: existingLanguage, error: selectError } = await supabase
      .from('languages')
      .select('id')
      .eq('code', code)
      .single();

    if (selectError && selectError.code !== 'PGRST116') {
      console.error('Error checking for existing language:', selectError);
      throw new Error('Failed to check for language');
    }

    if (existingLanguage) {
      console.log(`Found existing language with ID: ${existingLanguage.id}`);
      return existingLanguage.id;
    }

    // Create language if it doesn't exist
    const { data: newLanguage, error: insertError } = await supabase
      .from('languages')
      .insert({ code, name: getLanguageName(code) })
      .select('id')
      .single();

    if (insertError) {
      console.error('Error creating language:', insertError);
      throw new Error('Failed to create language');
    }

    console.log(`Created new language with ID: ${newLanguage.id}`);
    return newLanguage.id;
  } catch (error) {
    console.error('Error in getOrCreateLanguage:', error);
    throw error;
  }
}

// Get or create level
async function getOrCreateLevel(code, name, ordinal, languageId) {
  try {
    // Check if level exists
    const { data: existingLevel, error: selectError } = await supabase
      .from('language_levels')
      .select('id')
      .eq('code', code)
      .eq('language_id', languageId)
      .single();

    if (selectError && selectError.code !== 'PGRST116') {
      console.error('Error checking for existing level:', selectError);
      throw new Error('Failed to check for level');
    }

    if (existingLevel) {
      console.log(`Found existing level with ID: ${existingLevel.id}`);
      return existingLevel.id;
    }

    // Create level if it doesn't exist
    const { data: newLevel, error: insertError } = await supabase
      .from('language_levels')
      .insert({
        code,
        name,
        ordinal,
        language_id: languageId
      })
      .select('id')
      .single();

    if (insertError) {
      console.error('Error creating level:', insertError);
      throw new Error('Failed to create level');
    }

    console.log(`Created new level with ID: ${newLevel.id}`);
    return newLevel.id;
  } catch (error) {
    console.error('Error in getOrCreateLevel:', error);
    throw error;
  }
}

// Get or create topic
async function getOrCreateTopic(title, slug, canDoStatement, levelCode, levelId, orderInLevel) {
  try {
    // Create a safe slug (ensure it's URL-friendly)
    const safeSlug = slug.replace(/[^a-z0-9-]/g, '-').toLowerCase();
    
    // Check if topic exists
    const { data: existingTopic, error: selectError } = await supabase
      .from('topics')
      .select('id')
      .eq('slug', safeSlug)
      .single();

    if (selectError && selectError.code !== 'PGRST116') {
      console.error('Error checking for existing topic:', selectError);
      throw new Error('Failed to check for topic');
    }

    if (existingTopic) {
      console.log(`Found existing topic with ID: ${existingTopic.id}`);
      return existingTopic.id;
    }

    // Create topic if it doesn't exist
    const { data: newTopic, error: insertError } = await supabase
      .from('topics')
      .insert({
        title,
        slug: safeSlug,
        can_do_statement: canDoStatement,
        language_level_id: levelId,
        level_code: levelCode,
        order_in_level: orderInLevel
      })
      .select('id')
      .single();

    if (insertError) {
      console.error('Error creating topic:', insertError);
      throw new Error('Failed to create topic');
    }

    console.log(`Created new topic with ID: ${newTopic.id}`);
    return newTopic.id;
  } catch (error) {
    console.error('Error in getOrCreateTopic:', error);
    throw error;
  }
}

// Create a lesson
async function createLesson(title, slug, objective, topicId, orderInTopic) {
  try {
    // Create a safe slug
    const safeSlug = slug.replace(/[^a-z0-9-]/g, '-').toLowerCase();
    
    // Check if lesson exists
    const { data: existingLesson, error: selectError } = await supabase
      .from('lessons')
      .select('id')
      .eq('title', title)
      .eq('topic_id', topicId)
      .single();

    if (selectError && selectError.code !== 'PGRST116') {
      console.error('Error checking for existing lesson:', selectError);
      throw new Error('Failed to check for lesson');
    }

    if (existingLesson) {
      console.log(`Found existing lesson with ID: ${existingLesson.id}`);
      return existingLesson.id;
    }

    // Create lesson
    const { data: newLesson, error: insertError } = await supabase
      .from('lessons')
      .insert({
        title,
        content: null, // Not provided in the JSON
        topic_id: topicId,
        order_in_topic: orderInTopic
      })
      .select('id')
      .single();

    if (insertError) {
      console.error('Error creating lesson:', insertError);
      throw new Error('Failed to create lesson');
    }

    console.log(`Created new lesson with ID: ${newLesson.id}`);
    return newLesson.id;
  } catch (error) {
    console.error('Error in createLesson:', error);
    throw error;
  }
}

// Create a flashcard
async function createFlashcard(card, lessonId, orderInLesson) {
  try {
    // Create flashcard
    const { data: newCard, error: insertError } = await supabase
      .from('flashcards')
      .insert({
        word: card.front,
        translation: card.back,
        ipa: card.ipa || null,
        audio_url: null,
        image_url: null,
        example_sentence: card.example_sentence || '',
        grammar_explanation: card.grammar_explanation || null,
        lesson_id: lessonId,
        order_in_lesson: orderInLesson
      })
      .select('id')
      .single();

    if (insertError) {
      console.error('Error creating flashcard:', insertError);
      throw new Error('Failed to create flashcard');
    }

    console.log(`Created flashcard for word "${card.front}" with ID: ${newCard.id}`);
    return newCard.id;
  } catch (error) {
    console.error('Error in createFlashcard:', error);
    throw error;
  }
}

// Process a curriculum file
async function processFile(filePath) {
  try {
    console.log(`\nProcessing file: ${filePath}`);
    const fileContent = fs.readFileSync(filePath, 'utf8');
    const curriculum = JSON.parse(fileContent);
    
    // Extract the level code from the curriculum data
    const levelCode = curriculum.level_code;
    
    // Extract level name from the level code
    const levelNames = {
      'NL': 'Novice Low',
      'NM': 'Novice Mid',
      'NH': 'Novice High',
      'IL': 'Intermediate Low',
      'IM': 'Intermediate Mid',
      'IH': 'Intermediate High',
      'AL': 'Advanced Low',
      'AM': 'Advanced Mid',
      'AH': 'Advanced High',
      'S': 'Superior'
    };
    const levelName = levelNames[levelCode] || levelCode;
    
    console.log(`Level: ${levelCode} (${levelName})`);
    console.log(`Topic: ${curriculum.topic_title}`);
    console.log(`Lessons: ${curriculum.lessons?.length || 0}`);
    
    // Get or create language
    const languageId = await getOrCreateLanguage(LANGUAGE_CODE);
    console.log(`Language ID: ${languageId}`);
    
    // Get ordinal for level
    const levelOrdinals = {
      'NL': 1, // Novice Low
      'NM': 2, // Novice Mid
      'NH': 3, // Novice High
      'IL': 4, // Intermediate Low
      'IM': 5, // Intermediate Mid
      'IH': 6, // Intermediate High
      'AL': 7, // Advanced Low
      'AM': 8, // Advanced Mid
      'AH': 9, // Advanced High
      'S': 10   // Superior
    };
    const ordinal = levelOrdinals[levelCode] || 0;
    
    // Get or create level
    const levelId = await getOrCreateLevel(levelCode, levelName, ordinal, languageId);
    console.log(`Level ID: ${levelId}`);
    
    // Get or create topic
    const topicId = await getOrCreateTopic(
      curriculum.topic_title,
      curriculum.topic_slug,
      curriculum.can_do_statement,
      levelCode,
      levelId,
      1 // Default order
    );
    
    // Process lessons
    if (curriculum.lessons && curriculum.lessons.length > 0) {
      for (let i = 0; i < curriculum.lessons.length; i++) {
        const lesson = curriculum.lessons[i];
        
        // Create lesson
        const lessonId = await createLesson(
          lesson.title,
          lesson.slug || `lesson-${i+1}`,
          lesson.objective || null,
          topicId,
          i + 1
        );
        
        // Process cards
        if (lesson.cards && lesson.cards.length > 0) {
          for (let j = 0; j < lesson.cards.length; j++) {
            const card = lesson.cards[j];
            await createFlashcard(card, lessonId, j + 1);
          }
          console.log(`Added ${lesson.cards.length} cards to lesson ${lesson.title}`);
        }
      }
      console.log(`Added ${curriculum.lessons.length} lessons to topic ${curriculum.topic_title}`);
    }
    
    return true;
  } catch (error) {
    console.error(`Error processing file ${filePath}:`, error);
    return false;
  }
}

// Process all JSON files in the directory
async function processAllFiles() {
  try {
    console.log(`Looking for Spanish JSON files in: ${SPANISH_OUTPUT_DIR}`);
    
    // Read all JSON files from the directory
    const files = fs.readdirSync(SPANISH_OUTPUT_DIR)
      .filter(file => file.endsWith('.json'))
      .map(file => path.join(SPANISH_OUTPUT_DIR, file));
    
    console.log(`Found ${files.length} JSON files to process\n`);
    
    let successCount = 0;
    
    // Process each file
    for (const file of files) {
      const success = await processFile(file);
      if (success) {
        successCount++;
      }
    }
    
    console.log(`\nProcessing complete. ${successCount} of ${files.length} files processed successfully.`);
  } catch (error) {
    console.error('Error processing files:', error);
  }
}

// Run the script
processAllFiles(); 