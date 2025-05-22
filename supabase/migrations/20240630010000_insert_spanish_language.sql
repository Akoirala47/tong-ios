-- Insert Spanish language if it doesn't exist yet
INSERT INTO languages (code, name, native_name, created_at)
VALUES ('es', 'Spanish', 'Español', now())
ON CONFLICT (code) DO NOTHING; 