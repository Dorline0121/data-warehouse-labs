-- Lab 3 & Lab 4 — MySQL / MariaDB scripts (WampServer, phpMyAdmin)
-- Dorline TIAKO OKASSIE — each exercise is created in its own database (lab3_ex1, lab3_ex2…).
-- Import: phpMyAdmin > Import tab (at server level, with no database selected).
SET NAMES utf8mb4;

-- ================= lab3_ex1 =================
DROP DATABASE IF EXISTS lab3_ex1;
CREATE DATABASE lab3_ex1 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lab3_ex1;
-- Lab 3 – Exercise 1: star schema – disposable tableware sales
CREATE TABLE Dim_Time (
    id_time      INT AUTO_INCREMENT PRIMARY KEY,
    month_num    INT  NOT NULL,          -- 1..12
    month_name   VARCHAR(20) NOT NULL,
    quarter      INT  NOT NULL,          -- 1..4
    year         INT  NOT NULL
);

CREATE TABLE Dim_Product (
    id_product   INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    type         VARCHAR(50)  NOT NULL,  -- cup, plate, cutlery…
    category     VARCHAR(50)  NOT NULL   -- plastic, paper, biodegradable…
);

CREATE TABLE Dim_Location (
    id_location  INT AUTO_INCREMENT PRIMARY KEY,
    brand        VARCHAR(100) NOT NULL,  -- store brand
    outlet_type  VARCHAR(50)  NOT NULL,  -- supermarket, local shop, wholesaler
    address      VARCHAR(200),
    department   VARCHAR(50)  NOT NULL,
    region       VARCHAR(50)  NOT NULL
);

CREATE TABLE Fact_Sales (
    id_time       INT NOT NULL,
    id_product    INT NOT NULL,
    id_location   INT NOT NULL,
    quantity_sold INT            NOT NULL,   -- number of items sold
    unit_revenue  DECIMAL(10,2)  NOT NULL,   -- revenue per item sold
    PRIMARY KEY (id_time, id_product, id_location),
    FOREIGN KEY (id_time)     REFERENCES Dim_Time(id_time),
    FOREIGN KEY (id_product)  REFERENCES Dim_Product(id_product),
    FOREIGN KEY (id_location) REFERENCES Dim_Location(id_location)
);

INSERT INTO Dim_Time(month_num,month_name,quarter,year) VALUES (1,'January',1,2025),(4,'April',2,2025);
INSERT INTO Dim_Product(product_name,type,category) VALUES ('Cup 20cl','Cup','Paper'),('Plate 23cm','Plate','Biodegradable');
INSERT INTO Dim_Location(brand,outlet_type,address,department,region) VALUES ('Carrefour','Supermarket','1 A Street','Rhône','Auvergne-Rhône-Alpes'),('Metro','Wholesaler','2 B Street','Nord','Hauts-de-France');
INSERT INTO Fact_Sales VALUES (1,1,1,1000,0.10),(1,2,2,500,0.30),(2,1,2,800,0.12);
-- Revenue by category, region and quarter
SELECT p.category, l.region, t.year, t.quarter,
       SUM(f.quantity_sold)                  AS nb_articles,
       SUM(f.quantity_sold * f.unit_revenue) AS chiffre_affaires
FROM Fact_Sales f
JOIN Dim_Product  p ON p.id_product  = f.id_product
JOIN Dim_Location l ON l.id_location = f.id_location
JOIN Dim_Time     t ON t.id_time     = f.id_time
GROUP BY p.category, l.region, t.year, t.quarter
ORDER BY t.year, t.quarter, chiffre_affaires DESC;


-- ================= lab3_ex2 =================
DROP DATABASE IF EXISTS lab3_ex2;
CREATE DATABASE lab3_ex2 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lab3_ex2;
-- Lab 3 – Exercise 2 – Q2.1: star schema
CREATE TABLE Dim_Date (
    id_date   INT AUTO_INCREMENT PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day       INT  NOT NULL,
    week      INT  NOT NULL,   -- ISO week number
    month     INT  NOT NULL,
    year      INT  NOT NULL
);
CREATE TABLE Dim_Food (
    id_food   INT AUTO_INCREMENT PRIMARY KEY,
    food_name VARCHAR(100) NOT NULL,   -- Big Burger, Medium Fries…
    type      VARCHAR(50)  NOT NULL,   -- burger, drink, dessert…
    category  VARCHAR(50)  NOT NULL    -- main course, side…
);
CREATE TABLE Dim_Restaurant (
    id_restaurant   INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_name VARCHAR(100) NOT NULL,
    city            VARCHAR(50)  NOT NULL,
    country         VARCHAR(50)  NOT NULL
);
CREATE TABLE Fact_Sales (
    id_date       INT NOT NULL,
    id_food       INT NOT NULL,
    id_restaurant INT NOT NULL,
    quantity_sold INT           NOT NULL,
    profit        DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (id_date, id_food, id_restaurant),
    FOREIGN KEY (id_date)       REFERENCES Dim_Date(id_date),
    FOREIGN KEY (id_food)       REFERENCES Dim_Food(id_food),
    FOREIGN KEY (id_restaurant) REFERENCES Dim_Restaurant(id_restaurant)
);

-- Lab 3 – Exercise 2 – Q2.3: new fact table at the restaurant × day grain
-- (it shares Dim_Date and Dim_Restaurant with Fact_Sales => constellation)
CREATE TABLE Fact_Orders (
    id_date       INT NOT NULL,
    id_restaurant INT NOT NULL,
    nb_orders     INT NOT NULL,
    PRIMARY KEY (id_date, id_restaurant),
    FOREIGN KEY (id_date)       REFERENCES Dim_Date(id_date),
    FOREIGN KEY (id_restaurant) REFERENCES Dim_Restaurant(id_restaurant)
);

INSERT INTO Dim_Date(full_date,day,week,month,year) VALUES ('2025-07-14',14,29,7,2025),('2025-12-20',20,51,12,2025);
INSERT INTO Dim_Food(food_name,type,category) VALUES ('Big Burger','Burger','Main course'),('Vanilla ice cream','Dessert','Dessert');
INSERT INTO Dim_Restaurant(restaurant_name,city,country) VALUES ('Opera Restaurant','Paris','France'),('Station Restaurant','Lyon','France');
INSERT INTO Fact_Sales VALUES (1,1,1,300,450),(1,2,1,200,180),(2,1,2,250,375),(2,2,2,20,18);
INSERT INTO Fact_Orders VALUES (1,1,420),(2,2,260);
-- Most profitable restaurants
SELECT r.restaurant_name, SUM(f.profit) AS profit_total
FROM Fact_Sales f JOIN Dim_Restaurant r ON r.id_restaurant=f.id_restaurant
GROUP BY r.restaurant_name ORDER BY profit_total DESC;
-- Seasonality: quantities per month and per type
SELECT d.year, d.month, a.type, SUM(f.quantity_sold) AS qte
FROM Fact_Sales f JOIN Dim_Date d ON d.id_date=f.id_date JOIN Dim_Food a ON a.id_food=f.id_food
GROUP BY d.year, d.month, a.type ORDER BY d.year, d.month, qte DESC;
-- Items per order (combining the two fact tables)
SELECT r.restaurant_name, d.full_date, o.nb_orders,
       (SELECT SUM(s.quantity_sold) FROM Fact_Sales s
         WHERE s.id_date=o.id_date AND s.id_restaurant=o.id_restaurant) AS nb_articles
FROM Fact_Orders o JOIN Dim_Restaurant r ON r.id_restaurant=o.id_restaurant
JOIN Dim_Date d ON d.id_date=o.id_date;


-- ================= lab3_ex2_snowflake =================
DROP DATABASE IF EXISTS lab3_ex2_snowflake;
CREATE DATABASE lab3_ex2_snowflake CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lab3_ex2_snowflake;
-- Lab 3 – Exercise 2 – Q2.2: snowflake schema (explicit hierarchies)
-- Time hierarchy: Day -> Week -> Month -> Year
CREATE TABLE Dim_Year  (id_year  INT AUTO_INCREMENT PRIMARY KEY, year INT NOT NULL);
CREATE TABLE Dim_Month (id_month INT AUTO_INCREMENT PRIMARY KEY, month INT NOT NULL, id_year INT,
                        FOREIGN KEY (id_year) REFERENCES Dim_Year(id_year));
CREATE TABLE Dim_Week  (id_week  INT AUTO_INCREMENT PRIMARY KEY, week INT NOT NULL, id_month INT,
                        FOREIGN KEY (id_month) REFERENCES Dim_Month(id_month));
CREATE TABLE Dim_Day   (id_date  INT AUTO_INCREMENT PRIMARY KEY, full_date DATE NOT NULL UNIQUE, id_week INT,
                        FOREIGN KEY (id_week) REFERENCES Dim_Week(id_week));
-- Geographic hierarchy: Restaurant -> City -> Country
CREATE TABLE Dim_Country (id_country INT AUTO_INCREMENT PRIMARY KEY, country_name VARCHAR(50) NOT NULL);
CREATE TABLE Dim_City    (id_city INT AUTO_INCREMENT PRIMARY KEY, city_name VARCHAR(50) NOT NULL, id_country INT,
                          FOREIGN KEY (id_country) REFERENCES Dim_Country(id_country));
CREATE TABLE Dim_Restaurant (id_restaurant INT AUTO_INCREMENT PRIMARY KEY, restaurant_name VARCHAR(100) NOT NULL,
                             id_city INT, FOREIGN KEY (id_city) REFERENCES Dim_City(id_city));
-- Product hierarchy: Food item -> Type -> Category
CREATE TABLE Dim_Category (id_category INT AUTO_INCREMENT PRIMARY KEY, category_name VARCHAR(50) NOT NULL);
CREATE TABLE Dim_Type     (id_type INT AUTO_INCREMENT PRIMARY KEY, type_name VARCHAR(50) NOT NULL, id_category INT,
                           FOREIGN KEY (id_category) REFERENCES Dim_Category(id_category));
CREATE TABLE Dim_Food     (id_food INT AUTO_INCREMENT PRIMARY KEY, food_name VARCHAR(100) NOT NULL, id_type INT,
                           FOREIGN KEY (id_type) REFERENCES Dim_Type(id_type));
-- The fact table does not change
CREATE TABLE Fact_Sales (
    id_date       INT NOT NULL,
    id_food       INT NOT NULL,
    id_restaurant INT NOT NULL,
    quantity_sold INT           NOT NULL,
    profit        DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (id_date, id_food, id_restaurant),
    FOREIGN KEY (id_date)       REFERENCES Dim_Day(id_date),
    FOREIGN KEY (id_food)       REFERENCES Dim_Food(id_food),
    FOREIGN KEY (id_restaurant) REFERENCES Dim_Restaurant(id_restaurant)
);


-- ================= lab3_ex3 =================
DROP DATABASE IF EXISTS lab3_ex3;
CREATE DATABASE lab3_ex3 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lab3_ex3;
-- Lab 3 – Exercise 3 – Q3.1: star schema (constellation with 2 fact tables)
CREATE TABLE Dim_Student (
    id_student  INT PRIMARY KEY,         -- idEtu
    last_name   VARCHAR(50), first_name VARCHAR(50),
    birth_date  DATE, address VARCHAR(200),
    hs_diploma  VARCHAR(50)              -- high school diploma
);
CREATE TABLE Dim_Course (
    id_course   INT PRIMARY KEY,         -- idC
    course_name VARCHAR(100),
    program     VARCHAR(100)             -- program
);
CREATE TABLE Dim_Teacher (
    id_teacher  INT PRIMARY KEY,         -- idEns
    last_name   VARCHAR(50), first_name VARCHAR(50),
    specialty   VARCHAR(100)
);
CREATE TABLE Dim_ExamType (
    id_type     INT PRIMARY KEY,
    exam_type   VARCHAR(30)              -- continuous assessment / final exam
);
CREATE TABLE Dim_Date (
    id_date       INT AUTO_INCREMENT PRIMARY KEY,
    full_date     DATE NOT NULL UNIQUE,
    month         INT, year INT,
    academic_year VARCHAR(9)             -- e.g. '2024-2025'
);
CREATE TABLE Dim_AcademicYear (
    id_ay         INT AUTO_INCREMENT PRIMARY KEY,
    academic_year VARCHAR(9) NOT NULL UNIQUE
);
-- Fact 1: exam results  (grain = 1 student × 1 course × 1 exam type × 1 date)
CREATE TABLE Fact_Grades (
    id_student INT NOT NULL,
    id_course  INT NOT NULL,
    id_type    INT NOT NULL,
    id_date    INT NOT NULL,
    grade      DECIMAL(4,2),
    PRIMARY KEY (id_student, id_course, id_type, id_date),
    FOREIGN KEY (id_student) REFERENCES Dim_Student(id_student),
    FOREIGN KEY (id_course)  REFERENCES Dim_Course(id_course),
    FOREIGN KEY (id_type)    REFERENCES Dim_ExamType(id_type),
    FOREIGN KEY (id_date)    REFERENCES Dim_Date(id_date)
);
-- Fact 2: teaching load (grain = 1 teacher × 1 course × 1 academic year)
CREATE TABLE Fact_TeacherLoad (
    id_teacher      INT NOT NULL,
    id_course       INT NOT NULL,
    id_ay           INT NOT NULL,
    teaching_hours  DECIMAL(6,1) DEFAULT 0,   -- Teach.nbHours
    discharge_hours DECIMAL(6,1) DEFAULT 0,   -- Responsible.dischargeHours
    PRIMARY KEY (id_teacher, id_course, id_ay),
    FOREIGN KEY (id_teacher) REFERENCES Dim_Teacher(id_teacher),
    FOREIGN KEY (id_course)  REFERENCES Dim_Course(id_course),
    FOREIGN KEY (id_ay)      REFERENCES Dim_AcademicYear(id_ay)
);

-- Operational (source) database tables, prefixed src_, used to test the load
CREATE TABLE src_Teach       (idC INT, idEns INT, nbHours DECIMAL(6,1), academic_year VARCHAR(9));
CREATE TABLE src_Responsible (idEns INT, idC INT, dischargeHours DECIMAL(6,1), academic_year VARCHAR(9));
CREATE TABLE src_Compose     (idEtu INT, idC INT, idType INT, grade DECIMAL(4,2), exam_date DATE);
INSERT INTO src_Teach VALUES (1,10,30,'2024-2025'),(1,11,12,'2024-2025'),(2,10,20,'2024-2025');
INSERT INTO src_Responsible VALUES (10,1,8,'2024-2025'),(12,2,6,'2024-2025');  -- 12 is responsible for course 2 without teaching it
INSERT INTO src_Compose VALUES (100,1,1,12,'2025-01-15'),(101,1,1,16,'2025-01-15'),(100,1,2,9,'2025-06-10'),(101,1,2,14,'2025-06-10'),(100,2,2,11,'2025-06-12');

INSERT INTO Dim_Student VALUES (100,'Dupont','Alice','2003-05-02','Paris','Bac S'),(101,'Martin','Paul','2002-11-20','Lille','Bac ES');
INSERT INTO Dim_Course VALUES (1,'Databases','ING3'),(2,'Data Warehouse','ING4');
INSERT INTO Dim_Teacher VALUES (10,'Durand','Sophie','Computer Science'),(11,'Bernard','Karim','Mathematics'),(12,'Leroy','Anne','Data');
INSERT INTO Dim_ExamType VALUES (1,'Continuous assessment'),(2,'Final exam');

-- ===== Q3.2 – Loading the fact tables from the operational database =====
INSERT INTO Dim_AcademicYear(academic_year)
SELECT academic_year FROM src_Teach UNION SELECT academic_year FROM src_Responsible;

INSERT INTO Dim_Date(full_date, month, year, academic_year)
SELECT DISTINCT exam_date, MONTH(exam_date), YEAR(exam_date),
       CASE WHEN MONTH(exam_date) >= 9
            THEN CONCAT(YEAR(exam_date), '-', YEAR(exam_date) + 1)
            ELSE CONCAT(YEAR(exam_date) - 1, '-', YEAR(exam_date)) END
FROM src_Compose;

INSERT INTO Fact_Grades(id_student, id_course, id_type, id_date, grade)
SELECT c.idEtu, c.idC, c.idType, d.id_date, c.grade
FROM src_Compose c JOIN Dim_Date d ON d.full_date = c.exam_date;

-- Teach and Responsible have the same grain (teacher, course, year): we merge them.
-- MySQL has no FULL OUTER JOIN: we emulate it with LEFT JOIN + UNION ALL of the rows
-- of Responsible with no match (a course leader who does not teach the course).
INSERT INTO Fact_TeacherLoad(id_teacher, id_course, id_ay, teaching_hours, discharge_hours)
SELECT x.idEns, x.idC, ay.id_ay, x.nbHours, x.dischargeHours
FROM (
    SELECT t.idEns, t.idC, t.academic_year, t.nbHours, COALESCE(r.dischargeHours, 0) AS dischargeHours
    FROM src_Teach t
    LEFT JOIN src_Responsible r
           ON r.idEns = t.idEns AND r.idC = t.idC AND r.academic_year = t.academic_year
    UNION ALL
    SELECT r.idEns, r.idC, r.academic_year, 0, r.dischargeHours
    FROM src_Responsible r
    LEFT JOIN src_Teach t
           ON t.idEns = r.idEns AND t.idC = r.idC AND t.academic_year = r.academic_year
    WHERE t.idEns IS NULL
) x
JOIN Dim_AcademicYear ay ON ay.academic_year = x.academic_year;

-- ===== Q3.2 – Computing the indicators =====
-- (a) Average student grade per course and per date
SELECT c.course_name, d.full_date, ROUND(AVG(f.grade), 2) AS avg_grade, COUNT(*) AS nb_copies
FROM Fact_Grades f
JOIN Dim_Course c ON c.id_course = f.id_course
JOIN Dim_Date   d ON d.id_date   = f.id_date
GROUP BY c.course_name, d.full_date
ORDER BY c.course_name, d.full_date;

-- (b) Number of teaching hours per teacher and per course
SELECT t.last_name, t.first_name, c.course_name, ay.academic_year,
       SUM(f.teaching_hours) AS teaching_hours
FROM Fact_TeacherLoad f
JOIN Dim_Teacher t       ON t.id_teacher = f.id_teacher
JOIN Dim_Course  c       ON c.id_course  = f.id_course
JOIN Dim_AcademicYear ay ON ay.id_ay     = f.id_ay
GROUP BY t.last_name, t.first_name, c.course_name, ay.academic_year
ORDER BY t.last_name, c.course_name;

-- (c) Number of discharge hours per teacher and per course
SELECT t.last_name, t.first_name, c.course_name, ay.academic_year,
       SUM(f.discharge_hours) AS discharge_hours
FROM Fact_TeacherLoad f
JOIN Dim_Teacher t       ON t.id_teacher = f.id_teacher
JOIN Dim_Course  c       ON c.id_course  = f.id_course
JOIN Dim_AcademicYear ay ON ay.id_ay     = f.id_ay
WHERE f.discharge_hours > 0
GROUP BY t.last_name, t.first_name, c.course_name, ay.academic_year
ORDER BY t.last_name, c.course_name;


-- ================= lab3_ex3_snowflake =================
DROP DATABASE IF EXISTS lab3_ex3_snowflake;
CREATE DATABASE lab3_ex3_snowflake CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lab3_ex3_snowflake;
-- Lab 3 – Exercise 3 – Q3.1: snowflake schema (normalized dimensions)
CREATE TABLE Dim_Diploma   (id_diploma INT AUTO_INCREMENT PRIMARY KEY, diploma_name VARCHAR(50));
CREATE TABLE Dim_Student   (id_student INT PRIMARY KEY, last_name VARCHAR(50), first_name VARCHAR(50),
                            birth_date DATE, address VARCHAR(200), id_diploma INT,
                            FOREIGN KEY (id_diploma) REFERENCES Dim_Diploma(id_diploma));
CREATE TABLE Dim_Program   (id_program INT AUTO_INCREMENT PRIMARY KEY, program_name VARCHAR(100));
CREATE TABLE Dim_Course    (id_course INT PRIMARY KEY, course_name VARCHAR(100), id_program INT,
                            FOREIGN KEY (id_program) REFERENCES Dim_Program(id_program));
CREATE TABLE Dim_Specialty (id_specialty INT AUTO_INCREMENT PRIMARY KEY, specialty_name VARCHAR(100));
CREATE TABLE Dim_Teacher   (id_teacher INT PRIMARY KEY, last_name VARCHAR(50), first_name VARCHAR(50),
                            id_specialty INT, FOREIGN KEY (id_specialty) REFERENCES Dim_Specialty(id_specialty));
CREATE TABLE Dim_ExamType  (id_type INT PRIMARY KEY, exam_type VARCHAR(30));
CREATE TABLE Dim_AcademicYear (id_ay INT AUTO_INCREMENT PRIMARY KEY, academic_year VARCHAR(9) UNIQUE);
CREATE TABLE Dim_Month     (id_month INT AUTO_INCREMENT PRIMARY KEY, month INT, id_ay INT,
                            FOREIGN KEY (id_ay) REFERENCES Dim_AcademicYear(id_ay));
CREATE TABLE Dim_Date      (id_date INT AUTO_INCREMENT PRIMARY KEY, full_date DATE UNIQUE, id_month INT,
                            FOREIGN KEY (id_month) REFERENCES Dim_Month(id_month));
CREATE TABLE Fact_Grades (
    id_student INT NOT NULL, id_course INT NOT NULL, id_type INT NOT NULL, id_date INT NOT NULL,
    grade DECIMAL(4,2),
    PRIMARY KEY (id_student, id_course, id_type, id_date),
    FOREIGN KEY (id_student) REFERENCES Dim_Student(id_student),
    FOREIGN KEY (id_course)  REFERENCES Dim_Course(id_course),
    FOREIGN KEY (id_type)    REFERENCES Dim_ExamType(id_type),
    FOREIGN KEY (id_date)    REFERENCES Dim_Date(id_date));
CREATE TABLE Fact_TeacherLoad (
    id_teacher INT NOT NULL, id_course INT NOT NULL, id_ay INT NOT NULL,
    teaching_hours DECIMAL(6,1) DEFAULT 0, discharge_hours DECIMAL(6,1) DEFAULT 0,
    PRIMARY KEY (id_teacher, id_course, id_ay),
    FOREIGN KEY (id_teacher) REFERENCES Dim_Teacher(id_teacher),
    FOREIGN KEY (id_course)  REFERENCES Dim_Course(id_course),
    FOREIGN KEY (id_ay)      REFERENCES Dim_AcademicYear(id_ay));


-- ================= lab3_ex4 =================
DROP DATABASE IF EXISTS lab3_ex4;
CREATE DATABASE lab3_ex4 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lab3_ex4;
-- Lab 3 – Exercise 4 – Q4.1: star schema
CREATE TABLE Dim_StudentProfile (      -- anonymous data: only the profile is kept
    id_profile INT AUTO_INCREMENT PRIMARY KEY,
    age        INT  NOT NULL,
    gender     CHAR(1) NOT NULL         -- 'F' / 'M'
);
CREATE TABLE Dim_Course (
    id_course   INT AUTO_INCREMENT PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL,
    course_type VARCHAR(20)  NOT NULL   -- 'Compulsory' / 'Optional'
);
CREATE TABLE Dim_Date (
    id_date   INT AUTO_INCREMENT PRIMARY KEY,
    exam_date DATE NOT NULL UNIQUE,
    semester  VARCHAR(10) NOT NULL,     -- 'S1' / 'S2'
    season    VARCHAR(10) NOT NULL,     -- 'Winter', 'Summer'…
    year      INT NOT NULL
);
CREATE TABLE Fact_Exam (
    id_exam    INT AUTO_INCREMENT PRIMARY KEY,   -- one fact = one exam taken
    id_profile INT NOT NULL,
    id_course  INT NOT NULL,
    id_date    INT NOT NULL,
    grade      DECIMAL(4,2) NOT NULL,
    is_passed  TINYINT NOT NULL CHECK (is_passed IN (0,1)),  -- 1 = passed
    FOREIGN KEY (id_profile) REFERENCES Dim_StudentProfile(id_profile),
    FOREIGN KEY (id_course)  REFERENCES Dim_Course(id_course),
    FOREIGN KEY (id_date)    REFERENCES Dim_Date(id_date)
);

INSERT INTO Dim_StudentProfile(age,gender) VALUES (22,'F'),(22,'M'),(21,'F');
INSERT INTO Dim_Course(course_name,course_type) VALUES ('Relational Database','Compulsory'),('Photography','Optional');
INSERT INTO Dim_Date(exam_date,semester,season,year) VALUES ('2002-01-20','S1','Winter',2002),('2003-01-18','S1','Winter',2003),('2003-06-10','S2','Summer',2003);
INSERT INTO Fact_Exam(id_profile,id_course,id_date,grade,is_passed) VALUES
 (1,1,1,12,1),(2,1,1,8,0),(1,1,2,15,1),(2,2,2,11,1),(3,1,3,9,0),(1,2,3,13,1),(2,1,3,10,1);

-- 1) Number of exam successes per course in 2003
SELECT c.course_name, SUM(f.is_passed) AS nb_success
FROM Fact_Exam f JOIN Dim_Course c ON c.id_course=f.id_course
                 JOIN Dim_Date d   ON d.id_date=f.id_date
WHERE d.year = 2003
GROUP BY c.course_name;
-- 2) Number of exam successes for compulsory courses in 2003
SELECT SUM(f.is_passed) AS nb_success
FROM Fact_Exam f JOIN Dim_Course c ON c.id_course=f.id_course
                 JOIN Dim_Date d   ON d.id_date=f.id_date
WHERE d.year = 2003 AND c.course_type = 'Compulsory';
-- 3) Number of exam successes by gender in 2003
SELECT p.gender, SUM(f.is_passed) AS nb_success
FROM Fact_Exam f JOIN Dim_StudentProfile p ON p.id_profile=f.id_profile
                 JOIN Dim_Date d           ON d.id_date=f.id_date
WHERE d.year = 2003
GROUP BY p.gender;
-- 4) 22-year-old students who passed the Relational Database exam
SELECT COUNT(*) AS nb_success_22
FROM Fact_Exam f JOIN Dim_StudentProfile p ON p.id_profile=f.id_profile
                 JOIN Dim_Course c         ON c.id_course=f.id_course
WHERE p.age = 22 AND c.course_name = 'Relational Database' AND f.is_passed = 1;
-- 5) Number of exam successes during the Winter semester of 2002
SELECT SUM(f.is_passed) AS nb_success
FROM Fact_Exam f JOIN Dim_Date d ON d.id_date=f.id_date
WHERE d.season = 'Winter' AND d.year = 2002;


-- ================= lab3_ex4_snowflake =================
DROP DATABASE IF EXISTS lab3_ex4_snowflake;
CREATE DATABASE lab3_ex4_snowflake CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lab3_ex4_snowflake;
-- Lab 3 – Exercise 4 – Q4.2: snowflake schema
CREATE TABLE Dim_Gender     (id_gender INT AUTO_INCREMENT PRIMARY KEY, gender_label VARCHAR(10));
CREATE TABLE Dim_StudentProfile (id_profile INT AUTO_INCREMENT PRIMARY KEY, age INT, id_gender INT,
                                 FOREIGN KEY (id_gender) REFERENCES Dim_Gender(id_gender));
CREATE TABLE Dim_CourseType (id_ctype INT AUTO_INCREMENT PRIMARY KEY, type_label VARCHAR(20));  -- Compulsory/Optional
CREATE TABLE Dim_Course     (id_course INT AUTO_INCREMENT PRIMARY KEY, course_name VARCHAR(100), id_ctype INT,
                             FOREIGN KEY (id_ctype) REFERENCES Dim_CourseType(id_ctype));
CREATE TABLE Dim_Year       (id_year INT AUTO_INCREMENT PRIMARY KEY, year INT);
CREATE TABLE Dim_Season     (id_season INT AUTO_INCREMENT PRIMARY KEY, season_label VARCHAR(10));
CREATE TABLE Dim_Semester   (id_semester INT AUTO_INCREMENT PRIMARY KEY, semester_label VARCHAR(10),
                             id_season INT, id_year INT,
                             FOREIGN KEY (id_season) REFERENCES Dim_Season(id_season),
                             FOREIGN KEY (id_year)   REFERENCES Dim_Year(id_year));
CREATE TABLE Dim_Date       (id_date INT AUTO_INCREMENT PRIMARY KEY, exam_date DATE UNIQUE, id_semester INT,
                             FOREIGN KEY (id_semester) REFERENCES Dim_Semester(id_semester));
CREATE TABLE Fact_Exam (
    id_exam INT AUTO_INCREMENT PRIMARY KEY,
    id_profile INT NOT NULL, id_course INT NOT NULL, id_date INT NOT NULL,
    grade DECIMAL(4,2), is_passed TINYINT CHECK (is_passed IN (0,1)),
    FOREIGN KEY (id_profile) REFERENCES Dim_StudentProfile(id_profile),
    FOREIGN KEY (id_course)  REFERENCES Dim_Course(id_course),
    FOREIGN KEY (id_date)    REFERENCES Dim_Date(id_date));


-- ================= lab3_ex5 =================
DROP DATABASE IF EXISTS lab3_ex5;
CREATE DATABASE lab3_ex5 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lab3_ex5;
CREATE TABLE Dim_Date (id_date INT AUTO_INCREMENT PRIMARY KEY, year INT, month INT, day_of_month INT,
  day_of_week VARCHAR(10), time_slot VARCHAR(20), hour INT, minute INT, holiday_flag BOOLEAN, event_flag BOOLEAN);
CREATE TABLE Dim_Household (id_household INT AUTO_INCREMENT PRIMARY KEY, subscriber_name VARCHAR(100), birth_year INT,
  region VARCHAR(50), department VARCHAR(50), district VARCHAR(50), city VARCHAR(50), neighborhood VARCHAR(50),
  family_status VARCHAR(30), household_income VARCHAR(30), socio_prof_category VARCHAR(50),
  sub_category VARCHAR(50), activity_domain VARCHAR(50), nb_adults INT, nb_children INT);
CREATE TABLE Dim_Broadcast (id_broadcast INT AUTO_INCREMENT PRIMARY KEY, channel VARCHAR(50), start_date DATETIME,
  duration_sec INT, program_type VARCHAR(50), category VARCHAR(50), advertiser VARCHAR(100));
CREATE TABLE Fact_Action (
  id_date INT NOT NULL,
  id_household INT NOT NULL,
  id_broadcast INT NOT NULL,
  action_type VARCHAR(30),          -- degenerate dimension
  action_duration INT,              -- measure (seconds)
  remaining_duration INT,           -- measure (seconds)
  parental_control_flag BOOLEAN,    -- flag
  FOREIGN KEY (id_date)      REFERENCES Dim_Date(id_date),
  FOREIGN KEY (id_household) REFERENCES Dim_Household(id_household),
  FOREIGN KEY (id_broadcast) REFERENCES Dim_Broadcast(id_broadcast));

INSERT INTO Dim_Date(year,month,day_of_month,day_of_week,time_slot,hour,minute,holiday_flag,event_flag) VALUES
 (2025,1,10,'Friday','Prime time',21,0,false,false),(2025,1,11,'Saturday','Morning',9,30,false,false),
 (2025,2,3,'Monday','Prime time',20,45,false,false),(2025,3,5,'Wednesday','Afternoon',15,0,false,false);
INSERT INTO Dim_Household(subscriber_name,region) VALUES ('Household A','IDF'),('Household B','PACA');
INSERT INTO Dim_Broadcast(channel,program_type,category,advertiser) VALUES
 ('TF1','Movie','Entertainment',NULL),('M6','Advertising','Auto','Renault'),('Arte','Documentary','Culture',NULL);
INSERT INTO Fact_Action VALUES
 (1,1,1,'Viewing',5400,600,false),(1,2,2,'InformationRequest',45,0,false),(2,1,3,'Viewing',1800,1200,false),
 (3,2,2,'InformationRequest',60,0,false),(3,1,2,'InformationRequest',30,0,true),(4,2,1,'Viewing',3600,0,false),
 (4,1,2,'InformationRequest',50,0,false);

-- Q5.2 – Cumulative viewing time per program type and per time slot
SELECT b.program_type, d.time_slot,
       SUM(f.action_duration) AS cumulative_viewing_sec
FROM Fact_Action f
JOIN Dim_Broadcast b ON b.id_broadcast = f.id_broadcast
JOIN Dim_Date      d ON d.id_date      = f.id_date
GROUP BY b.program_type, d.time_slot
ORDER BY b.program_type, d.time_slot;

-- Q5.3 – Top 10 most watched program types (cumulative time)
SELECT b.program_type, SUM(f.action_duration) AS cumulative_viewing_sec
FROM Fact_Action f
JOIN Dim_Broadcast b ON b.id_broadcast = f.id_broadcast
GROUP BY b.program_type
ORDER BY cumulative_viewing_sec DESC
LIMIT 10;

-- Q5.4 – Monthly report: information requests and associated duration, with progression
WITH monthly AS (
    SELECT d.year, d.month,
           COUNT(*)               AS nb_info_requests,
           SUM(f.action_duration) AS info_duration_sec
    FROM Fact_Action f
    JOIN Dim_Date d ON d.id_date = f.id_date
    WHERE f.action_type = 'InformationRequest'
    GROUP BY d.year, d.month
)
SELECT year, month, nb_info_requests, info_duration_sec,
       nb_info_requests - LAG(nb_info_requests) OVER (ORDER BY year, month) AS delta_requests,
       ROUND(100.0 * (nb_info_requests - LAG(nb_info_requests) OVER (ORDER BY year, month))
             / NULLIF(LAG(nb_info_requests) OVER (ORDER BY year, month), 0), 1) AS evolution_pct,
       SUM(nb_info_requests) OVER (ORDER BY year, month) AS cumulative_requests
FROM monthly
ORDER BY year, month;


-- ================= lab4_ex1_type1 =================
DROP DATABASE IF EXISTS lab4_ex1_type1;
CREATE DATABASE lab4_ex1_type1 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lab4_ex1_type1;
-- Lab 4 – Ex.1 – Create Dim_Student (ready for SCD Type 2)
CREATE TABLE Dim_Student (
    sk_student  INT AUTO_INCREMENT PRIMARY KEY,        -- surrogate key
    nk_student  INT          NOT NULL,      -- natural key (student number)
    last_name   VARCHAR(50)  NOT NULL,
    first_name  VARCHAR(50)  NOT NULL,
    address     VARCHAR(100) NOT NULL,
    diploma     VARCHAR(20),
    date_start  DATE         NOT NULL,      -- start of validity of the version
    date_end    DATE,                       -- end of validity (NULL = still valid)
    is_current  BOOLEAN      NOT NULL DEFAULT TRUE
);
-- Initial data (academic year 2022)
INSERT INTO Dim_Student (nk_student, last_name, first_name, address, diploma, date_start, date_end, is_current)
VALUES (101, 'Dupont', 'Alice', 'Paris', 'Bac S',  '2022-09-01', NULL, TRUE),
       (102, 'Martin', 'Paul',  'Lille', 'Bac ES', '2022-09-01', NULL, TRUE);

-- SCD Type 1: overwrite the old value (no history)
UPDATE Dim_Student
SET    address = 'Lyon'
WHERE  nk_student = 101 AND is_current = TRUE;

SELECT * FROM Dim_Student ORDER BY sk_student;


-- ================= lab4_ex1_type2 =================
DROP DATABASE IF EXISTS lab4_ex1_type2;
CREATE DATABASE lab4_ex1_type2 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lab4_ex1_type2;
-- Lab 4 – Ex.1 – Create Dim_Student (ready for SCD Type 2)
CREATE TABLE Dim_Student (
    sk_student  INT AUTO_INCREMENT PRIMARY KEY,        -- surrogate key
    nk_student  INT          NOT NULL,      -- natural key (student number)
    last_name   VARCHAR(50)  NOT NULL,
    first_name  VARCHAR(50)  NOT NULL,
    address     VARCHAR(100) NOT NULL,
    diploma     VARCHAR(20),
    date_start  DATE         NOT NULL,      -- start of validity of the version
    date_end    DATE,                       -- end of validity (NULL = still valid)
    is_current  BOOLEAN      NOT NULL DEFAULT TRUE
);
-- Initial data (academic year 2022)
INSERT INTO Dim_Student (nk_student, last_name, first_name, address, diploma, date_start, date_end, is_current)
VALUES (101, 'Dupont', 'Alice', 'Paris', 'Bac S',  '2022-09-01', NULL, TRUE),
       (102, 'Martin', 'Paul',  'Lille', 'Bac ES', '2022-09-01', NULL, TRUE);

-- SCD Type 2: close the old version, then insert a new row
START TRANSACTION;
UPDATE Dim_Student
SET    date_end   = DATE '2023-08-31',
       is_current = FALSE
WHERE  nk_student = 101 AND is_current = TRUE;

INSERT INTO Dim_Student (nk_student, last_name, first_name, address, diploma, date_start, date_end, is_current)
SELECT nk_student, last_name, first_name, 'Lyon', diploma, DATE '2023-09-01', NULL, TRUE
FROM   Dim_Student
WHERE  nk_student = 101 AND date_end = DATE '2023-08-31';
COMMIT;

SELECT * FROM Dim_Student ORDER BY sk_student;

-- Lab 4 – Ex.3: link each fact to the version valid on the fact's date
CREATE TABLE Fact_Grades (sk_student INT NOT NULL, sk_course INT, sk_examtype INT, sk_date INT, grade DECIMAL(4,2),
                          FOREIGN KEY (sk_student) REFERENCES Dim_Student(sk_student));
-- ETL load: look up the surrogate key valid on the exam date
INSERT INTO Fact_Grades (sk_student, sk_course, sk_examtype, sk_date, grade)
SELECT d.sk_student, s.sk_course, s.sk_examtype, s.sk_date, s.grade
FROM (SELECT 101 AS nk_student, 301 AS sk_course, 1 AS sk_examtype, DATE '2022-12-15' AS exam_date, 2022 AS sk_date, 14 AS grade
      UNION ALL
      SELECT 101, 301, 2, DATE '2023-12-15', 2023, 15) AS s
JOIN Dim_Student d
  ON  d.nk_student = s.nk_student
  AND s.exam_date >= d.date_start
  AND s.exam_date <= COALESCE(d.date_end, DATE '9999-12-31');

SELECT f.*, d.address FROM Fact_Grades f JOIN Dim_Student d USING (sk_student) ORDER BY sk_date;
-- Average by city: each grade stays assigned to the city where the student lived
SELECT d.address, AVG(f.grade) FROM Fact_Grades f JOIN Dim_Student d USING (sk_student) GROUP BY d.address;


-- ================= lab4_ex1_type3 =================
DROP DATABASE IF EXISTS lab4_ex1_type3;
CREATE DATABASE lab4_ex1_type3 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lab4_ex1_type3;
-- Lab 4 – Ex.1 – Create Dim_Student (ready for SCD Type 2)
CREATE TABLE Dim_Student (
    sk_student  INT AUTO_INCREMENT PRIMARY KEY,        -- surrogate key
    nk_student  INT          NOT NULL,      -- natural key (student number)
    last_name   VARCHAR(50)  NOT NULL,
    first_name  VARCHAR(50)  NOT NULL,
    address     VARCHAR(100) NOT NULL,
    diploma     VARCHAR(20),
    date_start  DATE         NOT NULL,      -- start of validity of the version
    date_end    DATE,                       -- end of validity (NULL = still valid)
    is_current  BOOLEAN      NOT NULL DEFAULT TRUE
);
-- Initial data (academic year 2022)
INSERT INTO Dim_Student (nk_student, last_name, first_name, address, diploma, date_start, date_end, is_current)
VALUES (101, 'Dupont', 'Alice', 'Paris', 'Bac S',  '2022-09-01', NULL, TRUE),
       (102, 'Martin', 'Paul',  'Lille', 'Bac ES', '2022-09-01', NULL, TRUE);

-- SCD Type 3: add a column for the previous value
ALTER TABLE Dim_Student ADD COLUMN previous_address VARCHAR(100);
ALTER TABLE Dim_Student ADD COLUMN address_change_date DATE;

UPDATE Dim_Student
SET    previous_address    = address,      -- MySQL evaluates left to right: copy BEFORE overwriting
       address             = 'Lyon',
       address_change_date = DATE '2023-09-01'
WHERE  nk_student = 101;

SELECT * FROM Dim_Student ORDER BY sk_student;


-- ================= lab4_ex2_type1 =================
DROP DATABASE IF EXISTS lab4_ex2_type1;
CREATE DATABASE lab4_ex2_type1 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lab4_ex2_type1;
-- Lab 4 – Ex.2 – Create Dim_Teacher (SCD Type 2)
CREATE TABLE Dim_Teacher (
    sk_teacher  INT AUTO_INCREMENT PRIMARY KEY,
    nk_teacher  INT          NOT NULL,
    last_name   VARCHAR(50)  NOT NULL,
    first_name  VARCHAR(50)  NOT NULL,
    specialty   VARCHAR(100) NOT NULL,
    date_start  DATE         NOT NULL,
    date_end    DATE,
    is_current  BOOLEAN      NOT NULL DEFAULT TRUE
);
INSERT INTO Dim_Teacher (nk_teacher, last_name, first_name, specialty, date_start)
VALUES (201, 'Durand',  'Sophie', 'Computer Sci.', '2022-09-01'),
       (202, 'Bernard', 'Karim',  'Mathematics',   '2022-09-01');

-- SCD Type 1: overwrite
UPDATE Dim_Teacher
SET    specialty = 'Artificial Intelligence'
WHERE  nk_teacher = 201;

SELECT * FROM Dim_Teacher ORDER BY sk_teacher;


-- ================= lab4_ex2_type2 =================
DROP DATABASE IF EXISTS lab4_ex2_type2;
CREATE DATABASE lab4_ex2_type2 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lab4_ex2_type2;
-- Lab 4 – Ex.2 – Create Dim_Teacher (SCD Type 2)
CREATE TABLE Dim_Teacher (
    sk_teacher  INT AUTO_INCREMENT PRIMARY KEY,
    nk_teacher  INT          NOT NULL,
    last_name   VARCHAR(50)  NOT NULL,
    first_name  VARCHAR(50)  NOT NULL,
    specialty   VARCHAR(100) NOT NULL,
    date_start  DATE         NOT NULL,
    date_end    DATE,
    is_current  BOOLEAN      NOT NULL DEFAULT TRUE
);
INSERT INTO Dim_Teacher (nk_teacher, last_name, first_name, specialty, date_start)
VALUES (201, 'Durand',  'Sophie', 'Computer Sci.', '2022-09-01'),
       (202, 'Bernard', 'Karim',  'Mathematics',   '2022-09-01');

-- SCD Type 2: new version
START TRANSACTION;
UPDATE Dim_Teacher
SET    date_end = DATE '2023-12-31', is_current = FALSE
WHERE  nk_teacher = 201 AND is_current = TRUE;

INSERT INTO Dim_Teacher (nk_teacher, last_name, first_name, specialty, date_start, date_end, is_current)
VALUES (201, 'Durand', 'Sophie', 'Artificial Intelligence', DATE '2024-01-01', NULL, TRUE);
COMMIT;

SELECT * FROM Dim_Teacher ORDER BY sk_teacher;

