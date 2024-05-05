-- ******************** Essential Tools ********************
-- Creating store procedure which returns average salary of difference experience level
DELIMITER $$
DROP PROCEDURE IF EXISTS getAverageSalary;
CREATE PROCEDURE getAverageSalary(job_name VARCHAR(50))
BEGIN
	SELECT
		experience_level,
        ROUND(AVG(salary_in_usd), 2) AS avg_salary
	FROM salaries
    WHERE job_title = job_name
    GROUP BY experience_level;
END $$
DELIMITER ;

-- Creating function to get the recent year record
DELIMITER $$
DROP FUNCTION IF EXISTS recentYear;
CREATE FUNCTION recentYear()
RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE result INT;
    SELECT MAX(work_year) INTO result FROM salaries;
    RETURN result;
END $$
DELIMITER ;



/*
	Que-1 [Talent Hotspots]:	Top 3 country where a large group of employees working
*/
SELECT
	company_location,
    COUNT(*) AS number_large_size
FROM salaries
WHERE company_size = "L"
GROUP BY company_location
ORDER BY number_large_size DESC
LIMIT 3;



/*
	Que-2 [Salary Insights]:	Highlight the job role whose are manager with their average salary
*/
SELECT
	job_title,
    ROUND(AVG(salary_in_usd), 2) AS avg_salary
FROM salaries
WHERE job_title LIKE "%Manager%"
GROUP BY job_title
ORDER BY avg_salary DESC;



/*
	Que-3 [Job Title Compensation]: Find out the average salary of Machine Learning Engineer 
    by different experience level
*/
CALL getAverageSalary('Machine Learning Engineer');



/*
	Que-4 [Geographic Salary Comparisons]:	List the job title of that country which average salary is greater than overall market salary
*/
SELECT
	job_title,
    company_location,
    country_salary,
    market_avg_salary
FROM (
	SELECT
		job_title,
		company_location,
		ROUND(AVG(salary_in_usd)) AS country_salary
	FROM salaries
	GROUP BY job_title, company_location
    ) a
JOIN (
	SELECT
		job_title,
		ROUND(AVG(salary_in_usd)) AS market_avg_salary
	FROM salaries
	GROUP BY job_title
    ) b USING (job_title)
WHERE country_salary > market_avg_salary
ORDER BY country_salary DESC;



/*
	Que-5 [Remote Work Preference]:	Highlight top 5 job title where people prefer remote job along their percentage from overall population
*/
SELECT
	job_title,
    COUNT(*) AS remote_job,
    ROUND((COUNT(*) / (SELECT COUNT(*) FROM salaries)) * 100, 2) AS remote_ratio
FROM salaries
WHERE remote_ratio = 100
GROUP BY job_title
ORDER BY remote_job DESC
LIMIT 5;



/*
	Que-6 [Salary Growth Trends]:	Highlight the job title whose average salary is increasing over the last three year
*/
WITH filter_job AS (
		SELECT
			job_title,
			COUNT(DISTINCT work_year) AS year_record,
			ROUND(AVG(salary_in_usd), 2) AS avg_salary
		FROM salaries
		WHERE work_year > recentYear() - 3
		GROUP BY job_title
		HAVING year_record = 3
	),
    job_growth AS (
		SELECT
			job_title,
			work_year,
			ROUND(AVG(salary_in_usd), 2) AS avg_salary
		FROM salaries
		WHERE 	job_title IN (SELECT job_title FROM filter_job) AND
				work_year > recentYear() - 3
		GROUP BY job_title, work_year
	)

SELECT
	job_title,
    MAX(CASE WHEN work_year = 2022 THEN avg_salary END) AS 2022_avg_salary,
    MAX(CASE WHEN work_year = 2023 THEN avg_salary END) AS 2023_avg_salary,
    MAX(CASE WHEN work_year = 2024 THEN avg_salary END) AS 2024_avg_salary
FROM job_growth
GROUP BY job_title
HAVING 	2022_avg_salary < 2023_avg_salary AND 
		2023_avg_salary < 2024_avg_salary
ORDER BY 2024_avg_salary DESC;



/*
	Que-7 [Optimizing Compensation]:	Highlight the job role and their average salary by the country who provides highest part time job
*/
WITH top_pt_work_country AS (
		SELECT
			company_location,
			COUNT(*) AS number_of_job
		FROM salaries
		WHERE employment_type = "PT"
		GROUP BY company_location
		ORDER BY number_of_job DESC
		LIMIT 1
	)

SELECT
	job_title,
    company_location,
    ROUND(AVG(salary_in_usd), 2) AS avg_salary
FROM salaries
WHERE	employment_type = "PT" AND
		company_location IN (SELECT company_location FROM top_pt_work_country)
GROUP BY job_title, company_location
ORDER BY avg_salary DESC;