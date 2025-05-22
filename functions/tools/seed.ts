import * as dotenv from 'dotenv';
dotenv.config();

import { GoogleGenerativeAI } from "@google/generative-ai";
import { createClient } from "@supabase/supabase-js";
import * as fs from "fs";
import * as path from "path";
import * as yaml from "js-yaml";
import { z } from "zod";
import { LessonBatch, LessonBatchType } from "./schema";
import { system, user, fixJson } from "./prompts";

// Environment variables should be loaded from .env file in production
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || "AIzaSyAXXaMHGOgDzyf4iUNs-5xG5ZysuvfiFR4";

// HARDCODED VALUES FOR TESTING
const SUPABASE_URL = "https://eexuddpbzkqtvwfeurml.supabase.co";
const SUPABASE_SERVICE_ROLE = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVleHVkZHBiemtxdHZ3ZmV1cm1sIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NjgxNzExNiwiZXhwIjoyMDYyMzkzMTE2fQ.9R1KPR_mfp4ycg-EDJgKtqPSIaUCMaC4mVcL2bHiMrE";

// Initialize Gemini API client
const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
const model = genAI.getGenerativeModel({
  model: "gemini-2.0-flash",
  generationConfig: { 
    temperature: 0.7, 
    maxOutputTokens: 8192,
    topP: 0.95
  }
});

// Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE);

// Get project root path (two levels up from this file)
const PROJECT_ROOT = path.resolve(path.join(__dirname, "../.."));

// Helper to load config
function loadConfig(langCode: string) {
  const configPath = path.join(PROJECT_ROOT, "seed", langCode, "config.yml");
  console.log(`Loading config from: ${configPath}`);
  try {
    const fileContents = fs.readFileSync(configPath, "utf8");
    return yaml.load(fileContents) as any;
  } catch (error) {
    console.error(`Error loading config for ${langCode}:`, error);
    throw error;
  }
}

// Helper to load Can-Do statements
function loadCanDos() {
  const canDoPath = path.join(PROJECT_ROOT, "prompts", "actfl_can_do.json");
  console.log(`Loading Can-Do statements from: ${canDoPath}`);
  try {
    const fileContents = fs.readFileSync(canDoPath, "utf8");
    return JSON.parse(fileContents) as Record<string, string[]>;
  } catch (error) {
    console.error("Error loading Can-Do statements:", error);
    throw error;
  }
}

// Helper to load sample vocabulary (if available)
function loadVocabulary(langCode: string) {
  const vocabPath = path.join(PROJECT_ROOT, "seed", langCode, "vocab.csv");
  console.log(`Looking for vocabulary file at: ${vocabPath}`);
  try {
    if (fs.existsSync(vocabPath)) {
      return fs.readFileSync(vocabPath, "utf8");
    }
    return "";
  } catch (error) {
    console.warn(`No vocabulary file found for ${langCode}, proceeding without it.`);
    return "";
  }
}

// Helper to log generated content
async function logGeneratedContent(
  langCode: string,
  levelCode: string,
  canDo: string,
  promptSent: string,
  contentReceived: string
) {
  const timestamp = new Date().toISOString();
  const logData = {
    timestamp,
    language: langCode,
    level: levelCode,
    can_do: canDo,
    prompt: promptSent,
    response: contentReceived,
  };

  // Save locally (for debugging)
  const logDir = path.join(PROJECT_ROOT, "seed", langCode, "logs");
  if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
  }
  fs.writeFileSync(
    path.join(logDir, `${timestamp}-${levelCode}.json`),
    JSON.stringify(logData, null, 2)
  );

  // Only log to Supabase if explicitly enabled
  const enableSupabaseLogging = process.env.ENABLE_SUPABASE_LOGGING === "true";
  if (enableSupabaseLogging && SUPABASE_URL && SUPABASE_SERVICE_ROLE) {
    try {
      const { error } = await supabase.storage
        .from("content-generation-log")
        .upload(`${langCode}/${levelCode}/${timestamp}.json`, JSON.stringify(logData));
      
      if (error) {
        console.error("Error storing log in Supabase:", error);
      }
    } catch (error) {
      console.error("Error uploading to Supabase Storage:", error);
    }
  }
}

// Helper to clean up AI response JSON
function cleanJsonResponse(text: string): string {
  // Remove markdown code blocks if present
  let cleaned = text.replace(/```(?:json)?\n/g, '').replace(/\n```$/g, '');
  
  // Trim whitespace
  cleaned = cleaned.trim();
  
  // If response starts with a non-JSON character, try to find where JSON begins
  if (cleaned.charAt(0) !== '{' && cleaned.charAt(0) !== '[') {
    const jsonStart = cleaned.indexOf('{');
    if (jsonStart >= 0) {
      cleaned = cleaned.substring(jsonStart);
    }
  }
  
  // Ensure it ends properly
  const lastBrace = Math.max(cleaned.lastIndexOf('}'), cleaned.lastIndexOf(']'));
  if (lastBrace >= 0 && lastBrace < cleaned.length - 1) {
    cleaned = cleaned.substring(0, lastBrace + 1);
  }
  
  return cleaned;
}

// Generate lessons using Gemini API
async function generateLessons(
  langCode: string,
  langName: string,
  levelCode: string,
  levelName: string,
  canDo: string,
  topicTemplate: string
): Promise<LessonBatchType> {
  const vocabCsv = loadVocabulary(langCode);

  const systemPrompt = system({ level: levelCode, levelName });
  const userPrompt = user({
    lang: langCode,
    langName,
    level: levelCode,
    levelName,
    canDo,
    topicTemplate,
    vocabCsv,
  });

  console.log(`Generating content for ${langName} (${levelCode}): "${canDo}"`);

  try {
    // Initialize chat with system prompt
    const chat = model.startChat({
      history: [
        {
          role: "user",
          parts: [{ text: systemPrompt }],
        },
        {
          role: "model",
          parts: [{ text: "I understand. I'll generate ACTFL-aligned content in the specified JSON format. Please provide the details for the lesson batch you need." }],
        },
      ],
    });

    // Send user prompt with Can-Do statement and get response
    const result = await chat.sendMessage(userPrompt);
    let responseText = result.response.text();
    
    // Log the prompt and response
    await logGeneratedContent(
      langCode,
      levelCode,
      canDo,
      userPrompt,
      responseText
    );

    // Parse and validate JSON response
    try {
      const cleanedResponse = cleanJsonResponse(responseText);
      console.log("Cleaned JSON response and attempting to parse");
      
      const jsonResponse = JSON.parse(cleanedResponse);
      return LessonBatch.parse(jsonResponse);
    } catch (error) {
      const err = error as Error;
      if (error instanceof z.ZodError || error instanceof SyntaxError) {
        console.warn("Invalid JSON received, attempting to fix...");
        
        // Try to fix JSON by asking Gemini
        const fixPrompt = fixJson(
          err.message,
          responseText
        );
        
        const fixResult = await chat.sendMessage(fixPrompt);
        let fixedResponse = fixResult.response.text();
        
        // Log the fix attempt
        await logGeneratedContent(
          langCode,
          levelCode,
          canDo + " (FIX ATTEMPT)",
          fixPrompt,
          fixedResponse
        );
        
        try {
          const cleanedFixedResponse = cleanJsonResponse(fixedResponse);
          console.log("Cleaned fixed JSON response and attempting to parse");
          
          const fixedJson = JSON.parse(cleanedFixedResponse);
          return LessonBatch.parse(fixedJson);
        } catch (secondError) {
          console.error("Failed to fix JSON:", secondError);
          throw new Error("Could not generate valid lesson content after fix attempt");
        }
      }
      
      throw error;
    }
  } catch (error) {
    console.error("Error generating lessons:", error);
    throw error;
  }
}

// Save content to output directory
async function saveContentToFile(
  langCode: string,
  levelCode: string,
  canDo: string,
  lessonBatch: LessonBatchType
): Promise<void> {
  // Create a filename based on the topic slug
  const filename = `${lessonBatch.topic_slug}.json`;
  
  // Ensure output directory exists
  const outputDir = path.join(PROJECT_ROOT, "seed", langCode, "output");
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }
  
  // Save to file
  const outputPath = path.join(outputDir, filename);
  fs.writeFileSync(outputPath, JSON.stringify(lessonBatch, null, 2));
  
  console.log(`✅ Saved content to ${outputPath}`);
}

// Upsert generated content to Supabase
async function upsertContent(
  langCode: string,
  lessonBatch: LessonBatchType
): Promise<void> {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE) {
    console.warn("Supabase credentials not provided, skipping database insert");
    return;
  }

  try {
    // Begin transaction
    const { data: langData, error: langError } = await supabase
      .from("languages")
      .select("id")
      .eq("code", langCode)
      .single();

    if (langError) {
      throw new Error(`Language not found: ${langError.message}`);
    }

    const langId = langData.id;

    // Get or create language_level
    const { data: levelData, error: levelError } = await supabase
      .from("language_levels")
      .select("id")
      .eq("language_id", langId)
      .eq("code", lessonBatch.level_code)
      .single();

    let levelId: number;
    if (levelError) {
      // Level doesn't exist, need to create it
      const config = loadConfig(langCode);
      const levelConfig = config.levels.find((l: any) => l.code === lessonBatch.level_code);
      
      if (!levelConfig) {
        throw new Error(`Level configuration not found for ${lessonBatch.level_code}`);
      }

      const { data: newLevel, error: newLevelError } = await supabase
        .from("language_levels")
        .insert({
          language_id: langId,
          code: lessonBatch.level_code,
          name: levelConfig.name,
          ordinal: levelConfig.ordinal,
          hours_target: levelConfig.hours_target
        })
        .select("id")
        .single();

      if (newLevelError) {
        throw new Error(`Failed to create level: ${newLevelError.message}`);
      }

      levelId = newLevel.id;
    } else {
      levelId = levelData.id;
    }

    // Create topic
    const { data: topicData, error: topicError } = await supabase
      .from("topics")
      .upsert({
        language_level_id: levelId,
        slug: lessonBatch.topic_slug,
        title: lessonBatch.topic_title,
        can_do_statement: lessonBatch.can_do_statement,
      })
      .select("id")
      .single();

    if (topicError) {
      throw new Error(`Failed to create topic: ${topicError.message}`);
    }

    const topicId = topicData.id;

    // Create lessons and flashcards
    for (let i = 0; i < lessonBatch.lessons.length; i++) {
      const lesson = lessonBatch.lessons[i];
      
      const { data: lessonData, error: lessonError } = await supabase
        .from("lessons")
        .upsert({
          topic_id: topicId,
          slug: lesson.slug,
          title: lesson.title,
          objective: lesson.objective,
          content: lesson.content || "",
          order_in_topic: i,
        })
        .select("id")
        .single();

      if (lessonError) {
        throw new Error(`Failed to create lesson: ${lessonError.message}`);
      }

      const lessonId = lessonData.id;

      // Create flashcards
      const flashcards = lesson.cards.map((card: any, cardIndex: number) => ({
        lesson_id: lessonId,
        word: card.front,
        translation: card.back,
        ipa: card.ipa || null,
        audio_url: card.audio_url || null,
        image_url: card.image_url || null,
        example_sentence: card.example_sentence,
        grammar_explanation: card.grammar_explanation || null,
        order_in_lesson: cardIndex
      }));

      const { error: cardsError } = await supabase
        .from("cards")
        .upsert(flashcards);

      if (cardsError) {
        throw new Error(`Failed to create flashcards: ${cardsError.message}`);
      }
    }

    const totalCards = lessonBatch.lessons.reduce((sum: number, lesson: any) => sum + lesson.cards.length, 0);
    console.log(`Successfully upserted topic: ${lessonBatch.topic_title} with 6 lessons and ${totalCards} flashcards`);
  } catch (error) {
    console.error("Error upserting content:", error);
    throw error;
  }
}

// Main function to seed content for a language level
async function seedLanguageLevel(
  langCode: string, 
  levelCode: string,
  canDoIndex: number = 0
): Promise<LessonBatchType> {
  // Load configuration for the language
  const config = loadConfig(langCode);
  const langName = config.name || langCode.toUpperCase();
  const canDos = loadCanDos();
  
  // Get the correct Can-Do statements for the level
  const levelCanDos = canDos[levelCode];
  if (!levelCanDos || levelCanDos.length === 0) {
    throw new Error(`No Can-Do statements found for level ${levelCode}`);
  }
  
  // Default to first Can-Do statement if index is out of bounds
  const canDoIndex_ = canDoIndex < 0 || canDoIndex >= levelCanDos.length 
    ? 0 
    : canDoIndex;
  
  const canDo = levelCanDos[canDoIndex_];
  console.log(`Selected Can-Do statement (index ${canDoIndex_}): "${canDo}"`);
  
  // Get level name
  const levelInfo = config.levels.find((l: any) => l.code === levelCode);
  if (!levelInfo) {
    throw new Error(`Level ${levelCode} not found in configuration`);
  }
  const levelName = levelInfo.name;
  
  // Generate topic template from Can-Do statement
  const topicSlug = canDo
    .toLowerCase()
    .replace(/[^\w\s]/g, '')
    .replace(/\s+/g, '-')
    .slice(0, 40);
  
  const topicTemplate = config.defaults?.topic_template || "I can {action} about {topic}";
  
  const lessonBatch = await generateLessons(
    langCode,
    langName,
    levelCode,
    levelName,
    canDo,
    topicTemplate
  );
  
  // Save content to local file
  await saveContentToFile(langCode, levelCode, canDo, lessonBatch);
  
  // Only upsert to Supabase if explicitly enabled
  const enableSupabaseUpsert = process.env.ENABLE_SUPABASE_UPSERT === "true";
  if (enableSupabaseUpsert && SUPABASE_URL && SUPABASE_SERVICE_ROLE) {
    await upsertContent(langCode, lessonBatch);
  } else {
    console.log("Skipping Supabase upsert (not enabled or credentials missing)");
  }
  
  return lessonBatch;
}

// Command-line interface
async function main() {
  // Parse command line arguments
  const args = process.argv.slice(2);
  let langCode = "es"; // Default to Spanish
  let levels: string[] = [];
  let canDoIndex = 0;
  
  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--lang" && args[i + 1]) {
      langCode = args[i + 1];
      i++;
    } else if (args[i] === "--levels" && args[i + 1]) {
      if (args[i + 1] === "all") {
        const config = loadConfig(langCode);
        levels = config.levels.map((l: any) => l.code);
      } else {
        levels = args[i + 1].split(",");
      }
      i++;
    } else if (args[i] === "--can-do-index" && args[i + 1]) {
      canDoIndex = parseInt(args[i + 1], 10);
      i++;
    }
  }
  
  if (levels.length === 0) {
    // Default to Novice Low if no levels specified
    levels = ["NL"];
  }
  
  console.log(`Seeding content for ${langCode}, levels: ${levels.join(", ")}`);
  
  for (const level of levels) {
    try {
      await seedLanguageLevel(langCode, level, canDoIndex);
      console.log(`✅ Successfully seeded ${level} for ${langCode}`);
    } catch (error) {
      console.error(`❌ Failed to seed ${level} for ${langCode}:`, error);
    }
  }
}

// Run the script if called directly
if (require.main === module) {
  main().catch(console.error);
}

export { seedLanguageLevel }; 