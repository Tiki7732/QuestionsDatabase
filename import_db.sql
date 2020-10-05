DROP TABLE IF EXISTS question_tags;
DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS question_likes;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS users;
PRAGMA foreign_keys = ON;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    fname VARCHAR(255) NOT NULL,
    lname VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
    id INTEGER PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    author_id INTEGER NOT NULL,

    FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    parent_reply_id INTEGER,
    author_id INTEGER NOT NULL,
    body TEXT NOT NULL,

    FOREIGN KEY (author_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (parent_reply_id) REFERENCES replies(id)
);

CREATE TABLE question_likes (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO 
    users (fname, lname)
VALUES 
    ('Joe', 'Blo'),
    ('Jeff', 'Heff'),
    ('Jim', 'Bim'),
    ('Mary', 'Bary'),
    ('Pam', 'Glam'),
    ('Sue', 'Drew');

INSERT INTO
    questions (title, body, author_id)
VALUES
    ('Electrical', "Motorcycle wont turn over! There is a clicking sound but nothing else",
    (SELECT id FROM users WHERE fname = 'Joe' AND lname = 'Blo')),

    ('Gas', "I cant get the gas to flow, there is gas in the tank but nothing at the injectors",
    (SELECT id FROM users WHERE fname = 'Jim' AND lname = 'Bim')),

    ('Air Flow', "How can I increase air flow through the carb?", 
    (SELECT id FROM users WHERE fname = 'Jeff' AND lname = 'Heff')),

    ('Tires', "Can I increase tire size without changing rim?", 
    (SELECT id FROM users WHERE fname = 'Mary' AND lname = 'Bary')),

    ('Chain', "My chain seems too loose, how much slack should I have?",
    (SELECT id FROM users WHERE fname = 'Sue' AND lname = 'Drew'));

INSERT INTO
    question_follows (user_id, question_id)
VALUES
    ((SELECT id FROM users WHERE fname = 'Pam' AND lname = 'Glam'),
    (SELECT id FROM questions WHERE title = 'Electrical')),
    ((SELECT id FROM users WHERE fname = 'Joe' AND lname = 'Blo'),
    (SELECT id FROM questions WHERE title = 'Chain')),
    ((SELECT id FROM users WHERE fname = 'Jeff' AND lname = 'Heff'),
    (SELECT id FROM questions WHERE title = 'Tires'));

INSERT INTO 
    replies (question_id, parent_reply_id, author_id, body)
VALUES
    ((SELECT id FROM questions WHERE title = 'Electrical'),
    NULL,
    (SELECT id FROM users WHERE fname = 'Jeff' AND lname = 'Heff'),
    'Check the battery');

INSERT INTO 
    replies (question_id, parent_reply_id, author_id, body)
VALUES 
    ((SELECT id FROM questions WHERE title = 'Electrical'),
    (SELECT id FROM replies WHERE body = 'Check the battery'),
    (SELECT id FROM users WHERE fname = 'Mary' AND lname = 'Bary'),
    'After the battery check the starter'),


    ((SELECT id FROM questions WHERE title = 'Chain'),
    NULL,
    (SELECT id FROM users WHERE fname = 'Pam' AND lname = 'Glam'),
    'You should have about an inch of slack when sitting on the bike');

INSERT INTO
    question_likes (user_id, question_id)
VALUES
    ((SELECT id FROM users WHERE fname = 'Pam' AND lname = 'Glam'),
    (SELECT id FROM questions WHERE title = 'Electrical')),
    ((SELECT id FROM users WHERE fname = 'Joe' AND lname = 'Blo'),
    (SELECT id FROM questions WHERE title = 'Chain')),
    ((SELECT id FROM users WHERE fname = 'Jeff' AND lname = 'Heff'),
    (SELECT id FROM questions WHERE title = 'Tires'));
