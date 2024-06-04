
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

INSERT INTO BigTask VALUES (0, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (1, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (2, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (3, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (4, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (5, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (6, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (7, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (9, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (10, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');

INSERT INTO BigTask VALUES (11, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (12, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (13, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (14, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (15, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (16, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (17, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (19, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');

INSERT INTO BigTask VALUES (20, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (21, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (22, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (23, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (24, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (25, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (26, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (27, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (29, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');

INSERT INTO BigTask VALUES (30, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (31, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (32, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (33, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (34, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (35, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (36, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (37, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (39, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');

INSERT INTO BigTask VALUES (40, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (41, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (42, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (43, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (44, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (45, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (46, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (47, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (49, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');

INSERT INTO BigTask VALUES (50, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (51, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (52, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (53, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (54, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (55, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (56, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (57, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (59, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');

INSERT INTO BigTask VALUES (60, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (61, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (62, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (63, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (64, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (65, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (66, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (67, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (69, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');

INSERT INTO BigTask VALUES (70, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (71, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (72, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (73, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (74, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (75, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (76, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (77, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (79, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');

INSERT INTO BigTask VALUES (80, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (81, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (82, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (83, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (84, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (85, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (86, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (87, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (89, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');

INSERT INTO BigTask VALUES (90, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (91, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (92, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (93, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (94, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (95, '123', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (96, '123', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (97, '123', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (99, '123', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
