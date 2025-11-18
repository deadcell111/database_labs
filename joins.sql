
--Task 1
SELECT
    'Unassigned Employee' AS type,
    e.emp_name AS emp_name,
    e.salary AS details
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.dept_id IS NULL

UNION

SELECT
    'Unsigned Project' AS type,
    p.project_name AS project_name,
    p.budget AS details
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
WHERE p.dept_id IS NULL;

--Task 2

SELECT
    d.dept_name,
    COUNT(DISTINCT e.emp_id) AS employee_count,
    COUNT(DISTINCT p.project_id) AS project_count,
    CASE
        WHEN COUNT(DISTINCT p.project_id) > COUNT(DISTINCT e.emp_id)
            THEN 'Overload'
        ELSE 'Balanced'
        END AS balanced_status
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.project_id
GROUP BY d.dept_name;

--Task 3

SELECT
    d.dept_name,
    SUM(e.salary) AS total_salaries,
    SUM(p.budget) AS total_budgets,
    CASE
        WHEN SUM(e.salary) > SUM(p.budget)
            THEN 'Salary Higher'
        ELSE 'Budget Higher'
        END AS higher_cost
FROM departments d
JOIN employees e ON d.dept_id = e.dept_id
JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_name;

--Task 4
SELECT
    e.emp_name,
    d.dept_name,
    p.project_name,
    (e.salary + p.budget) AS combined_value
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;

--Task 5

SELECT d.dept_name,
       COUNT(DISTINCT e.emp_id) AS employee_count,
       COUNT(DISTINCT p.project_id) AS project_count,
       CASE
           WHEN COUNT(DISTINCT e.emp_id) > 0 AND COUNT(DISTINCT p.project_id > 0) THEN 'Fully Operational'
           WHEN COUNT(DISTINCT e.emp_id) = 0 AND COUNT(DISTINCT p.project_id = 0) THEN 'Empty Department'
           WHEN COUNT(DISTINCT e.emp_id) = 0 AND COUNT(DISTINCT p.project_id > 0) THEN 'Needs Employees'
           WHEN COUNT(DISTINCT e.emp_id) > 0 AND COUNT(DISTINCT p.project_id = 0) THEN 'Needs Projects'
       END AS status
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_name;
