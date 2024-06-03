
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

CREATE TABLE BigTask (
    ID INTEGER PRIMARY KEY,
    ReferenceID TEXT NOT NULL,
    CustomerReferenceID TEXT NOT NULL,
    DateCreated TEXT NOT NULL,
    DateModified TEXT,
    Title TEXT NOT NULL,
    Description TEXT,
    Status TEXT CHECK(Status IN ('Raised', 'Completed', 'Deferred', 'Approved', 'In-Progress')),
    Priority TEXT CHECK(Priority IN ('High', 'Medium', 'Low')),
    ScheduledStartDate TEXT,
    ScheduledEndDate TEXT,
    ActualStartDate TEXT,
    ActualEndDate TEXT,
    SystemName TEXT,
    Location TEXT,
    FileReference TEXT,
    Comments TEXT
);

INSERT INTO BigTask VALUES (1, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (2, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (3, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (4, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
