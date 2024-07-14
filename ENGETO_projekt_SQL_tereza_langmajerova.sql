/*
 * 
 * Crete table t_tereza_langmajerova_project_sql_primary_final
 */

CREATE TABLE t_tereza_langmajerova_project_sql_primary_final (
	id int(11) not null AUTO_INCREMENT,
	record_type char(128) null,
	industry_branch_code char(1) null,
	category_code int(11) NULL,
	accounting_year int(11) NULL,
	value double NULL,
	PRIMARY KEY (id)
);

/*
 Insert values
*/

INSERT INTO  t_tereza_langmajerova_project_sql_primary_final (record_type, industry_branch_code, category_code,accounting_year,value)
SELECT    
		  'salary'
		, industry_branch_code
		, null
		, payroll_year
		, avg(value) AS value
FROM czechia_payroll cp 
WHERE	cp.calculation_code = 100 AND 
		cp.unit_code = 200 AND
		cp.value_type_code  = 5958 AND
		cp.industry_branch_code IS NOT NULL AND 
		cp.value IS NOT NULL
GROUP BY industry_branch_code, payroll_year 

INSERT INTO t_tereza_langmajerova_project_sql_primary_final (record_type, industry_branch_code, category_code,accounting_year,value)
SELECT	 
		 'product_price'
		, null
		, category_code
		, year(date_from) 
		, avg(Value) 
FROM  czechia_price cp 
GROUP BY  category_code,year(date_from)

SELECT * FROM  t_tereza_langmajerova_project_sql_primary_final

/*
	create views
*/

CREATE VIEW product_prices AS
	SELECT 
		  category_code
		, accounting_year
		, value
		, IFNULL(LAG(value) OVER (PARTITION BY category_code ORDER BY accounting_year ),0) AS previous_year_value
		, value - LAG(value) OVER ( PARTITION BY category_code ORDER BY accounting_year ) AS diff
		, ((value*100) / IFNULL(LAG(value) OVER (PARTITION BY category_code ORDER BY accounting_year ),0)) - 100 AS percentage_diff
	FROM  t_tereza_langmajerova_project_sql_primary_final 
	WHERE record_type = 'product_price' 
	ORDER BY Category_Code, accounting_year
			
CREATE VIEW salaries
SELECT 
	  industry_branch_code
	, accounting_year	  
	, value
	, IFNULL(LAG(value) OVER (PARTITION BY industry_branch_code ORDER BY accounting_year ),0) AS previous_year_value
	, value - LAG(value) OVER ( PARTITION BY industry_branch_code ORDER BY accounting_year ) AS diff
	, ((value*100) / IFNULL(LAG(value) OVER (PARTITION BY industry_branch_code ORDER BY accounting_year ),0)) - 100 AS percentage_diff
FROM t_tereza_langmajerova_project_sql_primary_final
WHERE record_type = 'salary'
ORDER BY industry_branch_code, accounting_year

SELECT *
FROM salaries;

SELECT *
FROM product_prices AS pp ;

/*
 *##########################################################################
 *1
 *##########################################################################
 */

SELECT  
	  s.accounting_year
	, cpib.Name
	, s.value 
	, s.previous_year_value 
	, CASE  
		WHEN s.value  < s.previous_year_value 
			THEN 'decreasing' 
			ELSE 'increasing' 
		END
	, s.diff
FROM salaries AS s
LEFT JOIN czechia_payroll_industry_branch cpib ON s.industry_branch_code = cpib.code 
ORDER BY cpib.Name, s.accounting_year


/*
 *##########################################################################
 *2
 *##########################################################################
 */

SELECT  
	  cpc.name
	, cpib.name	
	, p.accounting_year
	, p.value
	, s.value 
	, s.value/p.value as can_buy 
FROM t_tereza_langmajerova_project_sql_primary_final p 
	JOIN t_tereza_langmajerova_project_sql_primary_final s ON p.accounting_year = s.accounting_year AND s.record_type = 'salary'
	JOIN czechia_payroll_industry_branch cpib ON s.Industry_branch_code = cpib.code 
	JOIN czechia_price_category cpc ON p.Category_code = cpc.code 
WHERE
	p.record_type = 'product_price' AND 
	p.Category_Code IN (111301,114201) AND 
	p.accounting_year IN (2006,2018) 
ORDER BY CPC.Name, p.accounting_year,Cpib.Name
;

/*
 *##########################################################################
 *3
 *##########################################################################
 */

SELECT  
	  name
	, percentage_diff  
FROM 
	(SELECT
		CPC.name AS name
		, AVG(pp.percentage_diff) AS percentage_diff 
	FROM product_prices pp 
	JOIN czechia_price_category cpc on cpc.code = pp.category_code	
	GROUP BY pp.category_code
) C
WHERE percentage_diff > 0 
ORDER BY percentage_diff


/*
 *##########################################################################
 *4
 *##########################################################################
 */


SELECT  
	  salary.accounting_year
	, salary.percentage_diff AS salary_percentage_diff
	, products.percentage_diff AS product_percentage_diff
	, products.percentage_diff - salary.percentage_diff AS diff 
FROM (
	SELECT 
		  accounting_year
		, AVG(percentage_diff) AS percentage_diff 
	FROM salaries
 	WHERE percentage_diff IS NOT NULl GROUP BY accounting_year 
 	) salary
LEFT JOIN (
	SELECT 
		  accounting_year
		, AVG(percentage_diff) AS percentage_diff 
		FROM product_prices pp  
		WHERE pp.percentage_diff IS NOT NULL 
		GROUP BY pp.Accounting_Year 
	) products ON products.accounting_Year = salary.accounting_Year
ORDER BY salary.accounting_year

/*
 *##########################################################################
 *5
 *##########################################################################
 */

SELECT
	  salary.accounting_year
	, salary.value AS salary_value
	, products.value AS product_value	
	, e.gdp
FROM (
		SELECT 
			  accounting_year
			, AVG(value) AS value 
		FROM salaries 
		WHERE value IS NOT NULl 
		GROUP BY accounting_year 
	) salary
LEFT JOIN (
		SELECT 
			  accounting_year
			, AVG(value) AS value 
		FROM product_prices pp  
		WHERE pp.value IS NOT NULL 
		GROUP BY pp.Accounting_Year 
	) products ON products.Accounting_Year = salary.Accounting_Year
LEFT JOIN economies e ON e.YEAR = salary.accounting_year AND e.country = 'Czech Republic'
ORDER BY Salary.Accounting_year

/*
 * 
 * Crete table t_tereza_langmajerova_project_sql_secondary_final
 */

CREATE TABLE t_tereza_langmajerova_project_sql_secondary_final (
	country char(128) NOT NULL,
	`year` int(11) NULL,
	gdp double NULL,
	gini double NULL,
	taxes double NULL
);

/*
 Insert values
*/

INSERT INTO t_tereza_langmajerova_project_sql_secondary_final (country,`year`,gdp,gini,taxes)
SELECT 
	  country
	, YEAR
	, gdp
	, gini
	, taxes 
FROM economies e 
WHERE e.`year` BETWEEN 2000 AND 2021 AND 
country NOT IN ('Not classified') 
ORDER BY country,YEAR

SELECT * 
FROM t_tereza_langmajerova_project_sql_secondary_final
