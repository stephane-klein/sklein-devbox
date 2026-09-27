-- Example migration — replace with your actual schema
CREATE TABLE contacts (
    id         BIGINT                   GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    firstname  TEXT                     NOT NULL,
    lastname   TEXT                     NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);