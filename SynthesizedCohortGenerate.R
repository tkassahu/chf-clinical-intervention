# Load required library
library(data.table)
install.packages("truncnorm")
library(truncnorm)

# Parameters
num_patients <- 100
start_date <- as.Date("2022-01-01")

# Helper function to generate random dates
generate_dates <- function(start_date, n, max_offset = 365) {
  start_date + sample(0:max_offset, n, replace = TRUE)
}

# Generate new cohort data
set.seed(123) # For reproducibility
new_data <- data.table(
  patient = paste0("patient_", 1:num_patients),
  first_chf_date = generate_dates(start_date, num_patients),
  #first_gdmt_date = generate_dates(start_date, num_patients),
  age_at_time_of_diagnosis = round(runif(100, min = 40, max = 84)),
  alive_in_2_years=sample(c(0, 1), size = 100, replace = TRUE, prob = c(0.3, 0.7)),
  gender=sample(c("F", "M"), size = 100, replace = TRUE, prob = c(0.45, 0.55)),
  race=sample(
    c("black", "hawaiian", "white", "asian","other","native"),
    size = 100,
    replace = TRUE,
    prob = c(0.51, 0.02, 0.38, 0.04, 0.025, 0.025)
  ),
  income=round(rtruncnorm(100, a = 800, b = 999100, mean = 122000, sd = 195000)),
  max_encounter_date = generate_dates(start_date + 365, num_patients),
  #current_gdmt_compliance_status = sample(c("GDMT_Active", "GDMT_Not_Active"), num_patients, replace = TRUE),
  total_encounter_count_post_diagnosis = round(rtruncnorm(100, a = 2, b = 280, mean = 20, sd = 30)),#sample(1:100, num_patients, replace = TRUE),
  #ed_encounter_post_diagnosis = sample(0:10, num_patients, replace = TRUE),
  chf_ed_encounter_post_diagnosis = pmin(rpois(num_patients, lambda = 1.2 * 0.65), 3),
  # total_encounters_when_gdmt_compliant = sample(0:50, num_patients, replace = TRUE),
  # gdmt_compliant_ed_visits = sample(0:10, num_patients, replace = TRUE),
  # non_compliant_ed_visits = sample(0:10, num_patients, replace = TRUE),
  # chf_related_ed_visit_percentage = runif(num_patients, min = 0, max = 1),
  gdmt_aherence_rate = runif(num_patients, min = 0.62 * 1.25, max = 1.0),
  # gdmt_compliant_ed_rate = runif(num_patients, min = 0, max = 1),
  # avg_cost_per_patient_chf_ed_encounters = runif(num_patients, min = 12988 * 0.6, max = 12988),
  total_chf_cost = round(runif(num_patients, min = 12299*0.6, max = 12299))
  #avg_cost_per_patient_per_day_chf_ed_encounters = runif(num_patients, min = 100, max = 1000),
  #total_chf_ed_encounter_days = sample(0:30, num_patients, replace = TRUE)
)

View(new_data)

# Save as CSV
write.csv(new_data, "C:/Users/amina/OneDrive/Documents/Personal Docs/Georgetown/6002/Project/Generated_Cohort_12_12_Final.csv", row.names = FALSE)

# Print path to file
cat("File saved as: Generated_Cohort_Updated.csv\n")
