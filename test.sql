
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

-- TASK HEIRACHY
CREATE TABLE TaskHeirachy (
    user_id INTEGER,
    task_id INTEGER,
    lft INTEGER,
    rgt INTEGER,
    
    CONSTRAINT fk_user_id
        FOREIGN KEY (user_id) 
        REFERENCES users (user_id) 
        ON DELETE CASCADE,
    
    CONSTRAINT fk_task_id
        FOREIGN KEY (task_id) 
        REFERENCES tasks (id) 
        ON DELETE CASCADE
);

INSERT INTO TaskHeirachy VALUES(1,0,1,8);
INSERT INTO TaskHeirachy VALUES(1,1,2,3);
INSERT INTO TaskHeirachy VALUES(1,2,4,7);
INSERT INTO TaskHeirachy VALUES(1,3,5,6);
