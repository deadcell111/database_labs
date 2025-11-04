CREATE TABLE employees (
 emp_id INT PRIMARY KEY,
 emp_name VARCHAR(50),
 dept_id INT,
 salary DECIMAL(10, 2)
);

CREATE TABLE departments (
 dept_id INT PRIMARY KEY,
 dept_name VARCHAR(50),
 location VARCHAR(50)
);

CREATE TABLE projects (
 project_id INT PRIMARY KEY,
 project_name VARCHAR(50),
 dept_id INT,
 budget DECIMAL(10, 2)
);

INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown', NULL, 45000);

INSERT INTO departments (dept_id, dept_name, location)
VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Finance', 'Building C'),
(104, 'Marketing', 'Building D');

INSERT INTO projects (project_id, project_name, dept_id, budget)
VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000);

SELECT e.emp_name, d.dept_name
FROM employees e CROSS JOIN departments d;

--20 rows
--N = 5; M = 4; N * M = 20

SELECT e.emp_name, d.dept_name
FROM employees e INNER JOIN departments d ON TRUE;

SELECT e.emp_name, p.project_name
FROM employees e CROSS JOIN projects p;

SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

--Number of rows: 4
--Because inner join excludes rows where dept_id is missing

SELECT employees.emp_name, departments.dept_name, departments.location
FROM employees INNER JOIN departments USING (dept_id);

--"Connect these two tables in a column with the SAME NAME,  and as a result, show this column ONLY ONCE"

SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;

SELECT e.emp_name, d.dept_name, p.project_name
FROm employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON d.dept_id = p.dept_id;

SELECT e.emp_name, e.dept_id as emp_dept, d.dept_id as dept_dept, d.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;

--Tom Brown is <null>

SELECT emp_name, dept_id as emp_dept, dept_id as dept_dept, dept_id
FROM employees
LEFT JOIN departments USING(dept_id);

SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;

SELECT d.dept_name, COUNT(e.emp_id) as employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;

SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id;

SELECT d.dept_name, e.emp_name
FROM employees e
RIGHT JOIN departments d ON d.dept_id = e.dept_id
WHERE e.emp_id IS NULL;

SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id;

SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL JOIN projects p ON p.dept_id = d.dept_id;

SELECT
  CASE
    WHEN e.emp_id IS NULL THEN 'Department without employees'
    WHEN d.dept_id IS NULL THEN 'Employee without department'
    ELSE 'Matched'
  END AS record_status,
  e.emp_name,
  d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL OR e.dept_id IS NULL;

SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
  AND d.location = 'Building A';

SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';

SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
  AND d.location = 'Building A';

SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';

SELECT d.dept_name, e.emp_name, e.salary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id;

SELECT d.dept_name, e.emp_name, e.salary, p.project_name, p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;

ALTER TABLE employees ADD COLUMN manager_id INT;

UPDATE employees SET manager_id = 3 WHERE emp_id = 1;
UPDATE employees SET manager_id = 3 WHERE emp_id = 2;
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;
UPDATE employees SET manager_id = 3 WHERE emp_id = 4;
UPDATE employees SET manager_id = 3 WHERE emp_id = 5;

SELECT e.emp_name AS employee, m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;

SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;

/*
1. **INNER JOIN** — only matching rows; **LEFT JOIN** — all rows on the left; if there are no matches, NULL is substituted on the right.

2. **CROSS JOIN** — all possible combinations of rows from two tables.

3. For outer joins, the filter in **ON** preserves the rows on the left, while in **WHERE** it can remove them. For an INNER JOIN, there is no difference.

4. **COUNT(*) for a CROSS JOIN** = the number of rows in the first table × the number of rows in the second.

5. **NATURAL JOIN** automatically joins on columns with the same name.

6. **Risks of NATURAL JOIN**: changing the table structure can break the logic, making the code less clear.

7. To convert a **LEFT JOIN** to a RIGHT JOIN**, simply swap the tables.

8. **FULL OUTER JOIN** returns all rows from both tables, including those that have no matches.*/