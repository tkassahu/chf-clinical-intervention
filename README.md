# Congestive Heart Failure (CHF) Clinical Decision Support System

## Project Overview  
This project develops a **clinical decision support system (CDSS)** to improve **guideline-directed medical therapy (GDMT) adherence** for **Congestive Heart Failure (CHF) patients**. The goal is to **reduce emergency department (ED) visits** by ensuring clinicians apply best practices in CHF management.

## Objectives  
- Identify **CHF patients** at risk of decompensation.  
- Implement **real-time provider alerts** to improve GDMT adherence.  
- Assist providers in **ordering/documenting CHF interventions** and patient follow-ups.  
- Monitor the **impact of interventions on CHF outcomes**, specifically **ED visits reduction**.  
- Provide stakeholders with **insights on intervention success rates**.  

## Clinical Context  
**Congestive Heart Failure (CHF)** is a chronic condition where the heart is unable to effectively pump blood to the lungs or body. Management relies on **guideline-directed medical therapy (GDMT)**, which includes keeping patients on the right medications. Without proper treatment, patients may experience worsening symptoms and require **emergency room visits or hospital admissions**.

### Problem Statement  
Your health system has identified **high rates of CHF exacerbations** and wants to push clinicians to improve GDMT adherence. The intervention aims to:  
- **Define the denominator** of CHF patients.  
- Track the percentage of patients **placed on GDMT** based on provided medication codes.  
- Measure whether the intervention **increases GDMT adherence and reduces ED visits**.  
- Ensure patients are on active medications **before follow-up visits** (data extracted from Synthea).

## Methodology  
### Data Sources & Processing  
- **Electronic Health Records (EHR) / Synthea Data**: Extract CHF patient demographics, medical history, and medication records.  
- **Guideline-Directed Medical Therapy (GDMT) Codes**: Identify prescribed CHF medications from EHR data.  
- **Emergency Department (ED) Visits**: Define and track **adverse events** (hospitalizations due to CHF exacerbation).  

### Features Extracted  
- **Patient demographics** (age, gender, comorbidities)  
- **Medication history** (active CHF medications before visits)  
- **Follow-up visit compliance** (scheduled vs. attended)  
- **ED visit history** (CHF-related admissions tracked over time)  

## Implementation: Clinical Decision Support System  
### 1. Provider Alerts for CHF Management  
- Notify providers when a CHF patient is due for a GDMT intervention.  
- Ensure alerts **appear in the provider’s EHR dashboard** before appointments.  

### 2. Order Assistance & Intervention Documentation  
- Streamline **medication ordering & documentation** within the EHR system.  
- Provide **pre-filled forms** for CHF interventions (e.g., ordering GDMT, scheduling follow-ups).  

### 3. Interface for New Encounter Types  
- Integrate telehealth visits, exercise counseling, and medication reviews into CHF management.  
- Track patient adherence and intervention completion.

### 4. Data Tracking & Outcome Reporting  
- Log **alerts triggered, interventions ordered, and ED visit reduction**.  
- Provide **dashboard analytics** for clinical performance monitoring.  

## How to Run the Code  
### 1. Clone the Repository  
```bash  
git clone https://github.com/tkassahu/chf-clinical-intervention.git  
cd chf-clinical-intervention  
