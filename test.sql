
-- USERS
CREATE TABLE users (user_id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, email TEXT);

INSERT INTO users (name, email) values ('Henry', 'henry@cool.com');
INSERT INTO users (name, email) values ('Joe', 'joe@foo.com');

-- SESSIONS
CREATE TABLE sessions (
    session_id INTEGER PRIMARY KEY,
    user_id INTEGER NULL,
    page_cache TEXT,

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

INSERT INTO BigTask VALUES (0, '1203', '456', '2020-01-01', '2020-01-02', 'Task 0', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (1, '1213', '456', '2020-01-01', '2020-01-02', 'Task 1', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (2, '1223', '456', '2020-01-01', '2020-01-02', 'Task 2', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (3, '1233', '456', '2020-01-01', '2020-01-02', 'Task 3', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (4, '1243', '456', '2020-01-01', '2020-01-02', 'Task 4', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (5, '1253', '456', '2020-01-01', '2020-01-02', 'Task 5', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (6, '1263', '456', '2020-01-01', '2020-01-02', 'Task 6', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (7, '1273', '456', '2020-01-01', '2020-01-02', 'Task 7', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (9, '1293', '456', '2020-01-01', '2020-01-02', 'Task 9', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (8, '1293', '456', '2020-01-01', '2020-01-02', 'Task 8', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (10, '11023', '456', '2020-01-01', '2020-01-02', 'Task 10', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');

INSERT INTO BigTask VALUES (11, '11123', '456', '2020-01-01', '2020-01-02', 'Task 11', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (12, '11223', '456', '2020-01-01', '2020-01-02', 'Task 12', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (13, '11323', '456', '2020-01-01', '2020-01-02', 'Task 13', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (14, '11423', '456', '2020-01-01', '2020-01-02', 'Task 14', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (15, '11523', '456', '2020-01-01', '2020-01-02', 'Task 15', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (16, '11623', '456', '2020-01-01', '2020-01-02', 'Task 16', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (17, '11723', '456', '2020-01-01', '2020-01-02', 'Task 17', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (18, '1293', '456', '2020-01-01', '2020-01-02', 'Task 18', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (19, '11923', '456', '2020-01-01', '2020-01-02', 'Task 19', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');

INSERT INTO BigTask VALUES (20, '12023', '456', '2020-01-01', '2020-01-02', 'Task 20', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (21, '12123', '456', '2020-01-01', '2020-01-02', 'Task 21', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (22, '12223', '456', '2020-01-01', '2020-01-02', 'Task 22', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (23, '12323', '456', '2020-01-01', '2020-01-02', 'Task 23', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (24, '12423', '456', '2020-01-01', '2020-01-02', 'Task 24', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (25, '12523', '456', '2020-01-01', '2020-01-02', 'Task 25', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (26, '12623', '456', '2020-01-01', '2020-01-02', 'Task 26', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (27, '12723', '456', '2020-01-01', '2020-01-02', 'Task 27', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (28, '1293', '456', '2020-01-01', '2020-01-02', 'Task 28', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (29, '12923', '456', '2020-01-01', '2020-01-02', 'Task 29', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');

INSERT INTO BigTask VALUES (30, '13023', '456', '2020-01-01', '2020-01-02', 'Task 30', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (31, '13123', '456', '2020-01-01', '2020-01-02', 'Task 31', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (32, '13223', '456', '2020-01-01', '2020-01-02', 'Task 32', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (33, '13323', '456', '2020-01-01', '2020-01-02', 'Task 33', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (34, '13423', '456', '2020-01-01', '2020-01-02', 'Task 34', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (35, '13523', '456', '2020-01-01', '2020-01-02', 'Task 35', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (36, '13623', '456', '2020-01-01', '2020-01-02', 'Task 36', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (37, '13723', '456', '2020-01-01', '2020-01-02', 'Task 37', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (38, '1293', '456', '2020-01-01', '2020-01-02', 'Task 38', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (39, '13923', '456', '2020-01-01', '2020-01-02', 'Task 39', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');

INSERT INTO BigTask VALUES (40, '14023', '456', '2020-01-01', '2020-01-02', 'Task 40', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (41, '14123', '456', '2020-01-01', '2020-01-02', 'Task 41', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (42, '14223', '456', '2020-01-01', '2020-01-02', 'Task 42', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (43, '14323', '456', '2020-01-01', '2020-01-02', 'Task 43', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (44, '14423', '456', '2020-01-01', '2020-01-02', 'Task 44', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (45, '14523', '456', '2020-01-01', '2020-01-02', 'Task 45', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (46, '14623', '456', '2020-01-01', '2020-01-02', 'Task 46', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (47, '14723', '456', '2020-01-01', '2020-01-02', 'Task 47', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (48, '1293', '456', '2020-01-01', '2020-01-02', 'Task 48', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (49, '14923', '456', '2020-01-01', '2020-01-02', 'Task 49', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');

INSERT INTO BigTask VALUES (50, '15023', '456', '2020-01-01', '2020-01-02', 'Task 50', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (51, '15123', '456', '2020-01-01', '2020-01-02', 'Task 51', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (52, '15223', '456', '2020-01-01', '2020-01-02', 'Task 52', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (53, '15323', '456', '2020-01-01', '2020-01-02', 'Task 53', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (54, '15423', '456', '2020-01-01', '2020-01-02', 'Task 54', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (55, '15523', '456', '2020-01-01', '2020-01-02', 'Task 55', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (56, '15623', '456', '2020-01-01', '2020-01-02', 'Task 56', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (57, '15723', '456', '2020-01-01', '2020-01-02', 'Task 57', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (58, '1293', '456', '2020-01-01', '2020-01-02', 'Task 58', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (59, '15923', '456', '2020-01-01', '2020-01-02', 'Task 59', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');

INSERT INTO BigTask VALUES (60, '16023', '456', '2020-01-01', '2020-01-02', 'Task 60', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (61, '16123', '456', '2020-01-01', '2020-01-02', 'Task 61', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (62, '16223', '456', '2020-01-01', '2020-01-02', 'Task 62', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (63, '16323', '456', '2020-01-01', '2020-01-02', 'Task 63', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (64, '16423', '456', '2020-01-01', '2020-01-02', 'Task 64', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (65, '16523', '456', '2020-01-01', '2020-01-02', 'Task 65', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (66, '16623', '456', '2020-01-01', '2020-01-02', 'Task 66', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (67, '16723', '456', '2020-01-01', '2020-01-02', 'Task 67', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (68, '1293', '456', '2020-01-01', '2020-01-02', 'Task 68', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (69, '16923', '456', '2020-01-01', '2020-01-02', 'Task 69', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');

INSERT INTO BigTask VALUES (70, '17023', '456', '2020-01-01', '2020-01-02', 'Task 70', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (71, '17123', '456', '2020-01-01', '2020-01-02', 'Task 71', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (72, '17223', '456', '2020-01-01', '2020-01-02', 'Task 72', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (73, '17323', '456', '2020-01-01', '2020-01-02', 'Task 73', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (74, '17423', '456', '2020-01-01', '2020-01-02', 'Task 74', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (75, '17523', '456', '2020-01-01', '2020-01-02', 'Task 75', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (76, '17623', '456', '2020-01-01', '2020-01-02', 'Task 76', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (77, '17723', '456', '2020-01-01', '2020-01-02', 'Task 77', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (78, '1293', '456', '2020-01-01', '2020-01-02', 'Task 78', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (79, '17923', '456', '2020-01-01', '2020-01-02', 'Task 79', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');

INSERT INTO BigTask VALUES (80, '18023', '456', '2020-01-01', '2020-01-02', 'Task 80', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (81, '18123', '456', '2020-01-01', '2020-01-02', 'Task 81', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (82, '18223', '456', '2020-01-01', '2020-01-02', 'Task 82', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (83, '18323', '456', '2020-01-01', '2020-01-02', 'Task 83', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (84, '18423', '456', '2020-01-01', '2020-01-02', 'Task 84', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (85, '18523', '456', '2020-01-01', '2020-01-02', 'Task 85', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (86, '18623', '456', '2020-01-01', '2020-01-02', 'Task 86', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (87, '18723', '456', '2020-01-01', '2020-01-02', 'Task 87', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (88, '1293', '456', '2020-01-01', '2020-01-02', 'Task 88', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (89, '18923', '456', '2020-01-01', '2020-01-02', 'Task 89', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');

INSERT INTO BigTask VALUES (90, '19023', '456', '2020-01-01', '2020-01-02', 'Task 90', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (91, '19123', '456', '2020-01-01', '2020-01-02', 'Task 91', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (92, '19223', '456', '2020-01-01', '2020-01-02', 'Task 92', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (93, '19323', '456', '2020-01-01', '2020-01-02', 'Task 93', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (94, '19423', '456', '2020-01-01', '2020-01-02', 'Task 94', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (95, '19523', '456', '2020-01-01', '2020-01-02', 'Task 95', 'Description 1', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 1', 'Location 1', 'File 1', 'Comments 1');
INSERT INTO BigTask VALUES (96, '19623', '456', '2020-01-01', '2020-01-02', 'Task 96', 'Description 2', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 2', 'Location 2', 'File 2', 'Comments 2');
INSERT INTO BigTask VALUES (97, '19723', '456', '2020-01-01', '2020-01-02', 'Task 97', 'Description 3', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 3', 'Location 3', 'File 3', 'Comments 3');
INSERT INTO BigTask VALUES (98, '1293', '456', '2020-01-01', '2020-01-02', 'Task 98', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
INSERT INTO BigTask VALUES (99, '19923', '456', '2020-01-01', '2020-01-02', 'Task 99', 'Description 4', 'Raised', 'High', '2020-01-01', '2020-01-02', '2020-01-01', '2020-01-02', 'System 4', 'Location 4', 'File 4', 'Comments 4');
