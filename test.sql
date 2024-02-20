
DROP TABLE users;
DROP TABLE sessions;
DROP TABLE tasks;

-- USERS 
CREATE TABLE users (user_id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, email TEXT);

INSERT INTO users (name, email) values ('Henry', 'henry@cool.com');
INSERT INTO users (name, email) values ('Joe', 'joe@foo.com');

-- SESSIONS
CREATE TABLE sessions (
    session_id INTEGER PRIMARY KEY, 
    user_id INTEGER NULL,
    
    CONSTRAINT fk_column
        FOREIGN KEY (user_id) 
        REFERENCES users (user_id) 
        ON DELETE CASCADE 
);

-- TASKS
CREATE TABLE tasks (
    id INTEGER PRIMARY KEY,
    task VARCHAR(255),
    status VARCHAR(255)
);

INSERT INTO tasks VALUES(0,'Buy groceries','Completed');
INSERT INTO tasks VALUES(1,'Finish that assignment','In-Progress');
INSERT INTO tasks VALUES(2,'Read a book','In-Progress');
INSERT INTO tasks VALUES(3,'Put out the washing','In-Progress');