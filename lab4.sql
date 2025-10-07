CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name varchar(50),
    last_name varchar(50),
    department varchar(50),
    salary numeric(10, 2),
    hire_date date,
    manager_id int,
    email varchar(100)
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name varchar(100),
    budget numeric(12, 2),
    start_date date,
    end_date date,
    status varchar(20)
);

CREATE TABLE assignments (
    assignment_id SERIAL PRIMARY KEY,
    employee_id int REFERENCES employees(employee_id),
    project_id int REFERENCES projects(project_id),
    hours_worked numeric(5, 1),
    assignment_date date
);

INSERT INTO employees (first_name, last_name, department, salary, hire_date, manager_id, email)
VALUES
        ('John', 'Smith', 'IT', 75000, '2020-01-15', NULL, 'john.smith@company.com'),
        ('Sarah', 'Johnson', 'IT', 65000, '2020-03-20', 1, 'sarah.j@company.com'),
        ('Michael', 'Brown', 'Sales', 55000, '2019-06-10', NULL, 'mbrown@company.com'),
        ('Emily', 'Davis', 'HR', 60000, '2021-02-01', NULL, 'emily.davis@company.com'),
        ('Robert', 'Wilson', 'IT', 70000, '2020-08-15', 1, NULL),
        ('Lisa', 'Anderson', 'Sales', 58000, '2021-05-20', 3, 'lisa.a@company.com');

INSERT INTO projects (project_name, budget, start_date, end_date, status)
VALUES
        ('Website Redesign', 150000, '2024-01-01', '2024-06-30', 'Active'),
        ('CRM Implementation', 200000, '2024-02-15', '2024-12-31', 'Active'),
        ('Marketing Campaign', 80000, '2024-03-01', '2024-05-31', 'Completed'),
        ('Database Migration', 120000, '2024-01-10', NULL, 'Active');

INSERT INTO assignments (employee_id, project_id, hours_worked, assignment_date)
VALUES
        (1, 1, 120.5, '2024-01-15'),
        (2, 1, 95.0, '2024-01-20'),
        (1, 4, 80.0, '2024-02-01'),
        (3, 3, 60.0, '2024-03-05'),
        (5, 2, 110.0, '2024-02-20'),
        (6, 3, 75.5, '2024-03-10');

--Part 1: Basic SELECT Queries

SELECT employees.first_name || ' ' || employees.last_name, employees.department, employees.salary FROM employees;

SELECT DISTINCT employees.department FROM employees;

SELECT projects.project_name, projects.budget,
       CASE
           WHEN projects.budget > 150000 THEN 'Large'
           WHEN projects.budget BETWEEN 100000 AND 150000 THEN 'Medium'
           ELSE 'Small'
           END AS budget_category FROM projects;

SELECT employees.first_name || ' ' || employees.last_name AS full_name,
       coalesce(employees.email, 'No email provided') AS email
FROM employees;

--Part 2

SELECT * FROM employees WHERE hire_date > DATE('2021-01-01');
SELECT * FROM employees WHERE salary BETWEEN 60000 AND 70000;
SELECT * FROM employees WHERE last_name LIKE 'S%' OR last_name LIKE 'J*';
SELECT * FROM employees WHERE manager_id IS NOT NULL AND department = 'IT';

--Part 3
SELECT
    upper(employees.first_name || ' ' || employees.last_name) AS full_name,
    length(employees.last_name) AS last_name_length,
    substring(employees.email FROM 1 FOR 3) AS email_prefix
FROM employees;

SELECT
    employees.first_name || ' ' || employees.last_name AS full_name,
    employees.salary * 12 AS annual_salary,
    round(employees.salary::numeric, 2) AS monthly_salary,
    employees.salary * 0.1 AS raise_amount
FROM employees;

SELECT format(
       'Project: %s - Budget: $%s - Status: %s',
       project_name,
       to_char(budget, 'FM999,999,999.00'),
    status
) AS project_summary FROM projects;

SELECT employees.first_name || ' ' || employees.last_name AS full_name,
       date_part('year', age(current_date, hire_date))::int AS years_with_company
FROM employees;

--Part 4
SELECT
    employees.department, avg(employees.salary) AS avg_salary
FROM employees
GROUP BY department;

SELECT p.project_name, coalesce(sum(a.hours_worked), 0) AS total_hours FROM projects p
LEFT JOIN assignments a ON a.project_id = p.project_id
GROUP BY p.project_name
ORDER BY p.project_name;

SELECT employees.department,
       count(*) AS employees_count
FROM employees GROUP BY department
HAVING count(*) > 1;

SELECT
    max(employees.salary) as max_salary,
    min(employees.salary) as min_salary,
    sum(employees.salary) as total_payroll
FROM employees;

--Part 5
SELECT employees.employee_id,
       employees.first_name || ' ' || employees.last_name AS full_name, salary
       FROM employees WHERE salary > 65000
UNION
SELECT employees.employee_id,
       employees.first_name || ' ' || employees.last_name AS full_name, salary
       FROM employees WHERE hire_date > date('2020-01-01');

SELECT employees.employee_id,
       employees.first_name || ' ' || employees.last_name AS full_name, salary
FROM employees WHERE department = 'IT'
INTERSECT
SELECT employees.employee_id,
       employees.first_name || ' ' || employees.last_name AS full_name, salary
FROM employees WHERE salary > 65000;

SELECT employees.employee_id,
       employees.first_name || ' ' || employees.last_name AS full_name
FROM employees
EXCEPT
SELECT employees.employee_id,
       employees.first_name || ' ' || employees.last_name AS full_name
FROM employees
JOIN assignments a on employees.employee_id = a.employee_id;

--Part 6
SELECT employees.employee_id,
       employees.first_name || ' ' || employees.last_name AS full_name
FROM employees
WHERE exists(
    SELECT 1
    FROM assignments
    WHERE assignments.employee_id = employees.employee_id
);

SELECT employees.employee_id,
       employees.first_name || ' ' || employees.last_name AS full_name
FROM employees
WHERE employee_id IN (
    SELECT employee_id
    FROM assignments
    WHERE project_id IN (
        SELECT project_id
        FROM projects
        WHERE status = 'Active'
        )
    );

SELECT employees.employee_id,
       employees.first_name || ' ' || employees.last_name AS full_name, employees.salary
FROM employees
WHERE salary > ANY (
    SELECT salary
    FROM employees
    WHERE department = 'Sales'
    );

--Part 7
SELECT employees.first_name || ' ' || employees.last_name AS full_name,
       employees.department,
       avg(assignments.hours_worked) AS avg_hours,
       rank() OVER (PARTITION BY employees.department ORDER BY employees.salary DESC) AS rank
FROM employees
LEFT JOIN assignments ON employees.employee_id = assignments.employee_id
GROUP BY employees.first_name, employees.last_name, employees.department, employees.salary;

SELECT
    p.project_name,
    SUM(a.hours_worked)                       AS total_hours,
    COUNT(DISTINCT a.employee_id)             AS employees_assigned
FROM assignments a
JOIN projects p ON p.project_id = a.project_id
GROUP BY p.project_name
HAVING SUM(a.hours_worked) > 150
ORDER BY total_hours DESC;

SELECT
  e1.department,
  COUNT(*) AS total_employees,
  ROUND(AVG(e1.salary), 2) AS avg_salary,
  (SELECT e2.first_name || ' ' || e2.last_name
   FROM employees e2
   WHERE e2.department = e1.department
   ORDER BY e2.salary DESC, e2.employee_id
   LIMIT 1) AS highest_paid_employee,

  ROUND(GREATEST(AVG(e1.salary), MIN(e1.salary)), 2) AS demo_greatest,
  ROUND(LEAST(AVG(e1.salary),  MAX(e1.salary)), 2)  AS demo_least
FROM employees e1
GROUP BY e1.department;

