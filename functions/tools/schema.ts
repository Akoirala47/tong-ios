import { z } from "zod";

// Schema for a single flashcard
export const Card = z.object({
  front: z.string().min(1, "Front side content is required"),
  back: z.string().min(1, "Back side translation is required"),
  ipa: z.string().optional(),
  audio_url: z.string().optional(),
  image_url: z.string().optional(),
  example_sentence: z.string().min(3, "Example sentence is required"),
  grammar_explanation: z.string().optional(),
});

// Schema for a single lesson
export const Lesson = z.object({
  slug: z.string().regex(/^[a-z0-9-]+$/, "Slug must be lowercase, alphanumeric with hyphens only"),
  title: z.string().min(3, "Title is required"),
  objective: z.string().min(10, "Lesson objective is required"),
  content: z.string().optional(),
  cards: z.array(Card).min(8, "At least 8 cards required").max(12, "Maximum 12 cards allowed"),
  order_in_topic: z.number().optional(),
});

// Schema for a batch of lessons in a topic
export const LessonBatch = z.object({
  level_code: z.string().min(2, "Level code is required"),
  topic_slug: z.string().regex(/^[a-z0-9-]+$/, "Topic slug must be lowercase, alphanumeric with hyphens only"),
  topic_title: z.string().min(3, "Topic title is required"),
  can_do_statement: z.string().min(5, "Can-do statement is required"),
  lessons: z.array(Lesson).length(6, "Exactly 6 lessons are required per topic"),
});

// Type inferences for TypeScript
export type CardType = z.infer<typeof Card>;
export type LessonType = z.infer<typeof Lesson>;
export type LessonBatchType = z.infer<typeof LessonBatch>; 