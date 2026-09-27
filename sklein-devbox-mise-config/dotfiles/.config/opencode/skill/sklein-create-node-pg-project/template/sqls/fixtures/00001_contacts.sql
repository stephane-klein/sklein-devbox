-- Example fixture data — replace with your actual seed data
INSERT INTO contacts (firstname, lastname)
     VALUES ('Alice', 'Martin'),
            ('Bob', 'Durand'),
            ('Charlie', 'Petit')
   ON CONFLICT DO NOTHING;
