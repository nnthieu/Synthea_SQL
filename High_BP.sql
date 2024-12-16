-- cd ./SyntheaData
-- ls
-- grep -i "systolic blood pressure" *.csv
-- Now, I know the file observation.csv is the file that I can find hbp patients

WITH hbp AS (
    SELECT 
        patient, 
        encounter,
        MAX(CASE WHEN code = '8462-4' THEN value::NUMERIC ELSE NULL END) AS dbp,
        MAX(CASE WHEN code = '8480-6' THEN value::NUMERIC ELSE NULL END) AS sbp
    FROM public.observations
    WHERE (code = '8462-4' AND value::NUMERIC >= 90)
       OR (code = '8480-6' AND value::NUMERIC >= 140)
    GROUP BY patient, encounter
)
SELECT 
    patient, 
    encounter,
    COALESCE(dbp, 90.0) AS adjusted_dbp,
    COALESCE(sbp, 140.0) AS adjusted_sbp
FROM hbp;

