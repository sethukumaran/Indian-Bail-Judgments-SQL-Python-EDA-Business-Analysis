-- Indian Bail Judgments: business-level SQL analysis
-- Load CSV into a table named bail_judgments before running.

-- 1. Dataset profile
SELECT COUNT(*) AS total_cases,
       COUNT(DISTINCT case_id) AS distinct_case_ids,
       COUNT(DISTINCT court) AS courts,
       COUNT(DISTINCT judge) AS judges,
       COUNT(DISTINCT region) AS regions,
       COUNT(DISTINCT crime_type) AS crime_types
FROM bail_judgments;

-- 2. Outcome mix
SELECT bail_outcome,
       COUNT(*) AS cases,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM bail_judgments), 2) AS pct_of_cases
FROM bail_judgments
GROUP BY bail_outcome
ORDER BY cases DESC;

-- 3. Annual outcome trend
SELECT CAST(strftime('%Y', date) AS INTEGER) AS year,
       COUNT(*) AS cases,
       SUM(CASE WHEN bail_outcome = 'Granted' THEN 1 ELSE 0 END) AS granted,
       ROUND(100.0 * AVG(CASE WHEN bail_outcome = 'Granted' THEN 1.0 ELSE 0.0 END), 2) AS grant_rate_pct
FROM bail_judgments
GROUP BY year
ORDER BY year;

-- 4. Crime type performance
SELECT crime_type,
       COUNT(*) AS cases,
       SUM(CASE WHEN bail_outcome = 'Granted' THEN 1 ELSE 0 END) AS granted,
       ROUND(100.0 * AVG(CASE WHEN bail_outcome = 'Granted' THEN 1.0 ELSE 0.0 END), 2) AS grant_rate_pct
FROM bail_judgments
GROUP BY crime_type
ORDER BY cases DESC;

-- 5. Court performance, suppressing small samples (<20 cases)
SELECT court,
       COUNT(*) AS cases,
       SUM(CASE WHEN bail_outcome = 'Granted' THEN 1 ELSE 0 END) AS granted,
       ROUND(100.0 * AVG(CASE WHEN bail_outcome = 'Granted' THEN 1.0 ELSE 0.0 END), 2) AS grant_rate_pct
FROM bail_judgments
GROUP BY court
HAVING COUNT(*) >= 20
ORDER BY grant_rate_pct DESC;

-- 6. Prior criminal case signal
SELECT prior_cases,
       COUNT(*) AS cases,
       ROUND(100.0 * AVG(CASE WHEN bail_outcome = 'Granted' THEN 1.0 ELSE 0.0 END), 2) AS grant_rate_pct
FROM bail_judgments
GROUP BY prior_cases
ORDER BY grant_rate_pct DESC;

-- 7. Parity argument signal
SELECT parity_argument_used,
       COUNT(*) AS cases,
       ROUND(100.0 * AVG(CASE WHEN bail_outcome = 'Granted' THEN 1.0 ELSE 0.0 END), 2) AS grant_rate_pct
FROM bail_judgments
GROUP BY parity_argument_used
ORDER BY parity_argument_used;

-- 8. Bail type
SELECT bail_type,
       COUNT(*) AS cases,
       ROUND(100.0 * AVG(CASE WHEN bail_outcome = 'Granted' THEN 1.0 ELSE 0.0 END), 2) AS grant_rate_pct
FROM bail_judgments
GROUP BY bail_type
ORDER BY cases DESC;

-- 9. Gender
SELECT accused_gender,
       COUNT(*) AS cases,
       ROUND(100.0 * AVG(CASE WHEN bail_outcome = 'Granted' THEN 1.0 ELSE 0.0 END), 2) AS grant_rate_pct
FROM bail_judgments
GROUP BY accused_gender
ORDER BY cases DESC;

-- 10. Cancellation and landmark cases
SELECT bail_cancellation_case,
       landmark_case,
       COUNT(*) AS cases,
       ROUND(100.0 * AVG(CASE WHEN bail_outcome = 'Granted' THEN 1.0 ELSE 0.0 END), 2) AS grant_rate_pct
FROM bail_judgments
GROUP BY bail_cancellation_case, landmark_case
ORDER BY cases DESC;

-- 11. High-volume regional comparison
SELECT region,
       COUNT(*) AS cases,
       SUM(CASE WHEN bail_outcome = 'Granted' THEN 1 ELSE 0 END) AS granted,
       ROUND(100.0 * AVG(CASE WHEN bail_outcome = 'Granted' THEN 1.0 ELSE 0.0 END), 2) AS grant_rate_pct
FROM bail_judgments
GROUP BY region
HAVING COUNT(*) >= 20
ORDER BY grant_rate_pct DESC;

-- 12. Potential data-quality audit
SELECT
    SUM(CASE WHEN prior_cases = 'Unknown' THEN 1 ELSE 0 END) AS prior_cases_unknown,
    SUM(CASE WHEN bias_flag = 1 THEN 1 ELSE 0 END) AS bias_flag_true,
    SUM(CASE WHEN bail_type IN ('Unknown','Not applicable','Others') THEN 1 ELSE 0 END) AS nonstandard_bail_type,
    COUNT(DISTINCT date) AS distinct_dates
FROM bail_judgments;

-- 13. Text-signal proxy analysis
-- Note: keyword presence is an association, not a causal/legal inference.
WITH text AS (
    SELECT case_id, bail_outcome,
           LOWER(COALESCE(judgment_reason,'') || ' ' ||
                 COALESCE(legal_issues,'') || ' ' ||
                 COALESCE(summary,'')) AS txt
    FROM bail_judgments
)
SELECT 'parity' AS keyword,
       COUNT(*) AS cases,
       ROUND(100.0 * AVG(CASE WHEN bail_outcome='Granted' THEN 1.0 ELSE 0.0 END), 2) AS grant_rate_pct
FROM text WHERE txt LIKE '%parity%'
UNION ALL
SELECT 'custody', COUNT(*),
       ROUND(100.0 * AVG(CASE WHEN bail_outcome='Granted' THEN 1.0 ELSE 0.0 END), 2)
FROM text WHERE txt LIKE '%custody%'
UNION ALL
SELECT 'evidence', COUNT(*),
       ROUND(100.0 * AVG(CASE WHEN bail_outcome='Granted' THEN 1.0 ELSE 0.0 END), 2)
FROM text WHERE txt LIKE '%evidence%'
UNION ALL
SELECT 'delay', COUNT(*),
       ROUND(100.0 * AVG(CASE WHEN bail_outcome='Granted' THEN 1.0 ELSE 0.0 END), 2)
FROM text WHERE txt LIKE '%delay%'
UNION ALL
SELECT 'gravity', COUNT(*),
       ROUND(100.0 * AVG(CASE WHEN bail_outcome='Granted' THEN 1.0 ELSE 0.0 END), 2)
FROM text WHERE txt LIKE '%gravity%';
