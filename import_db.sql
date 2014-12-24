DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
);

DROP TABLE IF EXISTS questions;
CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL
);

DROP TABLE IF EXISTS question_followers;
CREATE TABLE question_followers (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL
);

DROP TABLE IF EXISTS replies;
CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  parent_id INTEGER,
  user_id INTEGER NOT NULL,
  body TEXT NOT NULL
);

DROP TABLE IF EXISTS question_likes;
CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL
);


INSERT INTO
  users (fname, lname)
VALUES
  ('John', 'Doe'),
  ('James', 'Smith'),
  ('Kelly', 'Howard'),
  ('Brian', 'Skallebrini');

INSERT INTO
  questions(title, body, author_id)
VALUES
  ('SQL Question', 'How to SQL?',
     (SELECT id FROM users WHERE fname = 'John' AND lname = 'Doe')),
  ('JS Question', 'How to JS',
       (SELECT id FROM users WHERE fname = 'John' AND lname = 'Doe')),
  ('No Likes Question', 'How to like',
       (SELECT id FROM users WHERE fname = 'John' AND lname = 'Doe')),
  ('Rails Question', 'How to Rails?',
       (SELECT id FROM users WHERE fname = 'Brian' AND lname = 'Skallebrini')),
  ('Ruby Question', 'How to Ruby?',
    (SELECT id FROM users WHERE fname = 'James' AND lname = 'Smith'));

INSERT INTO
  replies (question_id, parent_id, user_id, body)
VALUES
  ((SELECT id FROM questions WHERE title = 'SQL Question'), NULL,
  (SELECT id FROM users WHERE fname = 'Kelly' AND lname = 'Howard'), 'First reply Body' ),
  ((SELECT id FROM questions WHERE title = 'SQL Question'), 1,
  (SELECT id FROM users WHERE fname = 'Brian' AND lname = 'Skallebrini'), 'Second reply Body' );

INSERT INTO
  question_followers (question_id, user_id)
VALUES
  ((SELECT id FROM questions WHERE title = 'SQL Question'), (SELECT id FROM users WHERE fname = 'Kelly' AND lname = 'Howard')),
  ((SELECT id FROM questions WHERE title = 'Ruby Question'), (SELECT id FROM users WHERE fname = 'Brian' AND lname = 'Skallebrini')),
  ((SELECT id FROM questions WHERE title = 'Ruby Question'), (SELECT id FROM users WHERE fname = 'John' AND lname = 'Doe'));

INSERT INTO
  question_likes (user_id, question_id)
VALUES
  ((SELECT id FROM users WHERE fname = 'John' AND lname = 'Doe'), (SELECT id FROM questions WHERE title = 'SQL Question')),
  ((SELECT id FROM users WHERE fname = 'John' AND lname = 'Doe'), (SELECT id FROM questions WHERE title = 'Ruby Question')),
  ((SELECT id FROM users WHERE fname = 'John' AND lname = 'Doe'), (SELECT id FROM questions WHERE title = 'JS Question')),
  ((SELECT id FROM users WHERE fname = 'John' AND lname = 'Doe'), (SELECT id FROM questions WHERE title = 'Rails Question')),
  ((SELECT id FROM users WHERE fname = 'Brian' AND lname = 'Skallebrini'), (SELECT id FROM questions WHERE title = 'SQL Question')),
  ((SELECT id FROM users WHERE fname = 'Kelly' AND lname = 'Howard'), (SELECT id FROM questions WHERE title = 'SQL Question')),
  ((SELECT id FROM users WHERE fname = 'James' AND lname = 'Smith'), (SELECT id FROM questions WHERE title = 'Ruby Question'));
