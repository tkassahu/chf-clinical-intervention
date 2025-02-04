# 1. CHF patients  
# 2. GDMT flag-current (whether they have medications active)
# 3. first date when CHF diagnosis was found
# 3. GDMT adherence score (number of times we have encounters for the person there were GDMT adherent)
# 4. Total Number of visits
# 5. Total Number of ED visits
# 6. Cost to hospital per patient


library(tidyverse)     # loads the tidyverse tools
library(RPostgres)     # loads the database driver for PostgreSQL
library(connections)   # helps RPostgres work with RStudio
library(keyring)       # access to a local encrypted keychain for passwords
library(data.table)


con <- connection_open(RPostgres::Postgres(),
                       dbname = "syntheticmguh",
                       host = "34.145.215.95",
                       user = "hids502_student",
                       password = key_get(service = "syntheticmguh", 
                                          username = "hids502_student"),
                       # Tell the driver to return very large integers as floating point (vs truncating them)
                       bigint = "numeric")

query <- "
WITH chf_patients AS (
    SELECT DISTINCT
        patients.id AS patient,
        MIN(conditions.start) AS chf_start_date,
        MAX(conditions.stop) AS chf_end_date
    FROM patients
    INNER JOIN conditions
        ON patients.id = conditions.patient
    WHERE conditions.code IN ('88805009', '84114007')
    GROUP BY patients.id
),
encounter_summary AS (
    SELECT
        a.patient,
        max(b.stop) encounter_stop_date,
        COUNT(DISTINCT b.id) AS total_encounters,
        COUNT(DISTINCT CASE WHEN b.encounterclass in ('emergency') THEN b.id ELSE null END) AS total_ed_visits,
        COUNT(DISTINCT CASE 
            WHEN b.encounterclass in ('emergency') 
                 AND (b.reasondescription='Chronic congestive heart failure (disorder)' OR b.reasondescription is null)
            THEN b.id 
            ELSE NULL 
        END) AS chf_ed_visits,
        AVG(b.total_claim_cost) AS avg_cost,
        SUM(CASE 
            WHEN b.encounterclass in ('emergency') 
                 AND (b.reasondescription='Chronic congestive heart failure (disorder)' OR b.reasondescription is null)
            THEN b.total_claim_cost 
            ELSE 0 
        END) AS total_chf_cost,
        SUM(CASE 
            WHEN b.encounterclass in ('emergency') 
                 AND (b.reasondescription='Chronic congestive heart failure (disorder)' OR b.reasondescription is null)
            THEN b.total_claim_cost 
            ELSE 0 
        END) / NULLIF(SUM(CASE 
            WHEN b.encounterclass in ('emergency') 
                 AND (b.reasondescription='Chronic congestive heart failure (disorder)' OR b.reasondescription is null)
            THEN 1 
            ELSE 0 
        END), 0) AS avg_chf_cost
    FROM chf_patients a
    LEFT JOIN encounters b
        ON a.patient = b.patient
        AND DATE(b.start) BETWEEN a.chf_start_date AND (a.chf_start_date + INTERVAL '2 years')
    GROUP BY a.patient
),
encounter_days AS (
SELECT patient,sum(total_encounter_days) as total_encounter_days FROM (
SELECT a.patient,b.id,
(CASE 
     WHEN b.stop IS NULL THEN CURRENT_DATE - MIN(b.start::date)
     WHEN b.start::date = b.stop::date THEN 1
     ELSE (b.stop::date - b.start::date) 
 END) AS total_encounter_days
FROM chf_patients a
    LEFT JOIN encounters b
        ON a.patient = b.patient
        AND DATE(b.start) BETWEEN a.chf_start_date AND (a.chf_start_date + INTERVAL '2 years')
    AND b.encounterclass in ('emergency') 
                 AND (b.reasondescription='Chronic congestive heart failure (disorder)' OR b.reasondescription is null)
    GROUP BY a.patient, b.id) as a GROUP BY 1
),
gdmt_medications AS (
    SELECT
        medications.patient,
        COUNT(DISTINCT medications.encounter) AS gdmt_compliant_visit,
        MIN(medications.start) AS med_start_date,
        MAX(COALESCE(medications.stop, '9999-12-31'::DATE)) AS med_end_date,
        COUNT(DISTINCT CASE
            WHEN medications.stop IS NULL OR medications.stop > CURRENT_DATE THEN medications.encounter
            ELSE NULL
        END) AS is_active,
        COUNT(DISTINCT CASE 
            WHEN medications.reasondescription = 'Chronic congestive heart failure (disorder)' 
            THEN medications.encounter 
            ELSE NULL 
        END) AS gdmt_encounters
    FROM chf_patients a
    LEFT JOIN medications
        ON a.patient = medications.patient
        AND DATE(medications.start) BETWEEN a.chf_start_date AND (a.chf_start_date + INTERVAL '2 years')
    WHERE medications.code IN ('313988', '200033', '979492', '314077', '1719286', '1656356') -- GDMT meds
    GROUP BY medications.patient
),
visit_frequency_and_compliance AS (
    SELECT
        e.patient,
        COUNT(DISTINCT e.id) AS visit_count,
        COUNT(DISTINCT CASE 
            WHEN e.start BETWEEN medications.start AND medications.stop 
            THEN e.id 
            ELSE NULL 
        END) AS compliant_visits,
        COUNT(DISTINCT CASE 
            WHEN e.encounterclass in ('emergency')
                 AND (e.reasondescription='Chronic congestive heart failure (disorder)' OR e.reasondescription is null)
                 AND e.start BETWEEN medications.start AND medications.stop
                  -- AND e.start >= medications.start AND e.stop <= COALESCE(medications.stop,CURRENT_DATE)
            THEN e.id 
            ELSE NULL 
        END) AS compliant_ed_visits,
        COUNT(DISTINCT CASE 
            WHEN e.encounterclass in ('emergency') 
                 AND (e.reasondescription='Chronic congestive heart failure (disorder)' OR e.reasondescription is null)
                 AND e.start NOT BETWEEN medications.start AND medications.stop 
            THEN e.id 
            ELSE NULL 
        END) AS non_compliant_ed_visits,
        COUNT(DISTINCT CASE 
            WHEN e.encounterclass in ('emergency') THEN e.id 
            ELSE NULL 
        END) AS ed_visits,
        COUNT(DISTINCT CASE 
            WHEN e.encounterclass in ('emergency') 
                 AND (e.reasondescription='Chronic congestive heart failure (disorder)' OR e.reasondescription is null)
            THEN e.id 
            ELSE NULL 
        END) AS chf_ed_visits,
        CASE 
            WHEN COUNT(DISTINCT e.id) = 0 THEN 0 
            ELSE COUNT(DISTINCT CASE 
                WHEN e.start BETWEEN medications.start AND medications.stop 
                THEN e.id 
                ELSE NULL 
            END) * 1.0 / COUNT(DISTINCT e.id) 
        END AS compliance_rate,
        CASE 
            WHEN COUNT(DISTINCT CASE 
                WHEN e.encounterclass in ('emergency') 
                     AND (e.reasondescription='Chronic congestive heart failure (disorder)' OR e.reasondescription is null)
                THEN e.id 
                ELSE NULL 
            END) = 0 THEN 0 
            ELSE COUNT(DISTINCT CASE 
                WHEN e.encounterclass in ('emergency') 
                     AND e.start BETWEEN medications.start AND medications.stop 
                THEN e.id 
                ELSE NULL 
            END) * 1.0 / COUNT(DISTINCT CASE 
                WHEN e.encounterclass in ('emergency')
                     AND (e.reasondescription='Chronic congestive heart failure (disorder)' OR e.reasondescription is null)
                THEN e.id 
                ELSE NULL 
            END) 
        END AS ed_compliance_rate
    FROM encounters e
    LEFT JOIN medications
        ON e.patient = medications.patient
    INNER JOIN chf_patients cp
        ON e.patient = cp.patient
        AND e.start BETWEEN cp.chf_start_date AND (cp.chf_start_date + INTERVAL '2 years')
    WHERE medications.code IN ('313988', '200033', '979492', '314077', '1719286', '1656356')
    GROUP BY e.patient
),
demographics AS (
SELECT ID, 
COALESCE(birthdate,CURRENT_DATE) birthdate,
COALESCE(deathdate,CURRENT_DATE) deathdate,
COALESCE(gender,'NA') gender,
COALESCE(race,'NA') race,
COALESCE(income,0) income
FROM patients
),
metrics AS (
    SELECT
        p.patient,
        MIN(p.chf_start_date) AS first_chf_date,
        EXTRACT('YEAR' FROM MAX(AGE(p.chf_start_date,birthdate))) AS age_at_time_of_diagnosis,
        SUM(CASE WHEN deathdate>= (encounter_summary.encounter_stop_date) then 1 else 0 end) as alive_in_2_years,
        MIN(gender) AS gender,
        MAX(deathdate) deathdate,
        MAX(race) race,
        MAX(income) income,
        MAX((encounter_summary.encounter_stop_date)) max_encounter_date,
        -- COALESCE(MIN(gdmt_medications.med_start_date),'1000-01-01'::DATE) AS first_gdmt_date,
        -- COALESCE(MAX(encounter_stop_date),'1000-01-01'::DATE) AS max_encounter_stop_date,
        COALESCE(MAX(visit_frequency_and_compliance.visit_count),0) AS total_encounter_count_post_diagnosis,
        -- COALESCE(SUM(visit_frequency_and_compliance.ed_visits),0) AS ed_encounter_post_diagnosis,
        COALESCE(SUM(encounter_summary.chf_ed_visits),0) AS chf_ed_encounter_post_diagnosis,
        COALESCE(MAX(visit_frequency_and_compliance.compliance_rate),0) AS gdmt_aherence_rate,
        COALESCE(MAX(encounter_summary.total_chf_cost)) total_chf_cost
    FROM chf_patients p
    LEFT JOIN encounter_summary
        ON p.patient = encounter_summary.patient
    LEFT JOIN gdmt_medications
        ON p.patient = gdmt_medications.patient
    LEFT JOIN visit_frequency_and_compliance
        ON p.patient = visit_frequency_and_compliance.patient
    LEFT JOIN encounter_days
        ON p.patient = encounter_days.patient
    LEFT JOIN demographics
        ON p.patient = demographics.ID
    GROUP BY p.patient
)
SELECT * FROM metrics
WHERE total_encounter_count_post_diagnosis>0; 
/* SELECT count(distinct patient) total_patients_with_chf, 
-- count(distinct case when gdmt_compliance_status='GDMT_Active' then patient else null end) Active_GDMT_Compliant_Patients, 
avg(chf_ed_encounter_post_diagnosis) Avg_CHF_Related_ED_Visit,
-- avg(ed_encounter_post_diagnosis) Avg_ED_Visit,
avg(gdmt_aherence_rate) Avg_GDMT_Adherence_Rate,
avg(total_chf_cost) total_chf_cost
FROM metrics where total_encounter_count_post_diagnosis>0 */
"
# total patients : 638
# total patients with a single encounter post diagnosis in 2 years: 313
# total patients with a single encounter post diagnosis in 2 years and alive after 2 years: 177

# Execute the query
results2 <- dbGetQuery(con, query)

# View the results
View(results2)

output2<-results2

write.csv(output2,"C:/Users/amina/OneDrive/Documents/Personal Docs/Georgetown/6002/Project/BaseCohort_12_12_Final.csv")
