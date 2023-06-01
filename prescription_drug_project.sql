--Q1A

SELECT DISTINCT npi, SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY npi
ORDER BY sum DESC;

--Q1B

SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER BY sum DESC;

SELECT nppes_provider_first_name, nppes_provider_mi, nppes_provider_last_org_name, specialty_description, COUNT(total_claim_count)
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE specialty_description = 'Internal Medicine' AND nppes_provider_first_name = 'JOHN' 
AND nppes_provider_last_org_name = 'WILLIAMS'
GROUP BY nppes_provider_first_name, nppes_provider_mi, nppes_provider_last_org_name, specialty_description;

--WHY do these not match up?? -- top 4 people listed have people with the same name. their claim counts are added together.

--Q2A

SELECT specialty_description, SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY specialty_description
ORDER BY sum DESC;

--Q2B

SELECT SUM(total_claim_count), specialty_description, opioid_drug_flag
FROM prescription
INNER JOIN drug
USING (drug_name)
INNER JOIN prescriber
USING(npi)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description, opioid_drug_flag
ORDER BY sum DESC;

--Q2C

SELECT COUNT(total_claim_count), specialty_description, opioid_drug_flag
FROM prescription
FULL JOIN drug
USING (drug_name)
FULL JOIN prescriber
USING(npi)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description, opioid_drug_flag
ORDER BY count;

--Q2D BONUS

SELECT COUNT(total_claim_count) AS claims, specialty_description,
	COUNT(*) * 100/ SUM(COUNT(*)) OVER() AS percentage_of_claims_with_opioids 
FROM prescription
FULL JOIN drug
USING (drug_name)
FULL JOIN prescriber
USING(npi)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY claims DESC;

--Q3A

SELECT generic_name, SUM(total_drug_cost)
FROM drug
INNER JOIN prescription
USING(drug_name)
GROUP BY generic_name
ORDER BY sum DESC;

--Q3B
SELECT generic_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply), 2) AS cost_per_day
FROM drug
INNER JOIN prescription
USING (drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC;

--OR

SELECT generic_name, ROUND(SUM(total_drug_cost/total_day_supply), 2) AS cost_per_day
FROM drug
INNER JOIN prescription
USING (drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC;

--shows cost per day for each row
SELECT generic_name, drug_name, total_drug_cost/SUM(total_day_supply) AS cost_per_day, (SELECT AVG(total_drug_cost/total_day_supply) FROM prescription)
FROM drug
INNER JOIN prescription
USING(drug_name)
WHERE generic_name ILIKE 'LEDIPASVIR%'
GROUP BY generic_name, drug_name, total_drug_cost;
--taken a rough average of values X the amount of cells gets close to the 88K

--Q4A

SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' 
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' ELSE 'neither' END AS drug_type 
FROM drug;


--Q4B

SELECT SUM(total_drug_cost):: money,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' 
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' ELSE 'neither' END AS drug_type 
FROM drug
INNER JOIN prescription
USING (drug_name)
GROUP BY drug_type;

--Q5A

SELECT *
FROM cbsa
WHERE cbsaname LIKE '%TN%';

--Q5B

SELECT SUM(population) AS total_pop, cbsaname
FROM population
INNER JOIN cbsa
USING(fipscounty)
WHERE cbsaname LIKE '%TN%'
GROUP BY cbsaname
ORDER BY total_pop DESC;

--Q5C

WITH total_pop AS
(SELECT fipscounty
FROM population
GROUP BY fipscounty
EXCEPT
SELECT fipscounty
FROM cbsa)

SELECT SUM(population), county
FROM total_pop
INNER JOIN population
USING (fipscounty)
INNER JOIN fips_county
ON population.fipscounty = fips_county.fipscounty
GROUP BY county
ORDER BY sum DESC;



--Q6A

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

--Q6B

SELECT drug_name, total_claim_count, opioid_drug_flag
FROM prescription
INNER JOIN drug
USING (drug_name)
WHERE total_claim_count >= 3000;

--OR

SELECT drug_name,total_claim_count,
CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
     ELSE 'Not_opioid' END AS category
FROM prescription
INNER JOIN drug
USING (drug_name)
WHERE total_claim_count>=3000
ORDER BY total_claim_count DESC;


--Q6C

SELECT nppes_provider_first_name, nppes_provider_last_org_name, drug_name, total_claim_count, opioid_drug_flag
FROM prescription
INNER JOIN drug
USING(drug_name)
INNER JOIN prescriber
USING (npi)
WHERE total_claim_count >= 3000;

--Q7A

SELECT npi, drug_name, specialty_description, nppes_provider_city
FROM prescriber
CROSS JOIN drug
WHERE nppes_provider_city = 'NASHVILLE' AND specialty_description = 'Pain Management' AND opioid_drug_flag ='Y'
ORDER BY npi;


--Q7B

SELECT prescriber.npi, drug.drug_name, SUM(total_claim_count)
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING (npi, drug_name)
WHERE nppes_provider_city ='NASHVILLE' AND specialty_description = 'Pain Management' AND opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, drug.drug_name 
ORDER BY sum DESC;

--Q7C

SELECT npi, drug_name, COALESCE(total_claim_count,0) AS total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING (npi, drug_name)
WHERE nppes_provider_city = 'NASHVILLE' AND specialty_description = 'Pain Management' AND opioid_drug_flag ='Y'
--GROUP BY npi, drug_name, total_claim_count
ORDER BY total_claims DESC;



WITH ggg AS
(SELECT npi, drug_name, COALESCE(total_claim_count,0) AS total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING (npi, drug_name)
WHERE nppes_provider_city = 'NASHVILLE' AND specialty_description = 'Pain Management' AND opioid_drug_flag ='Y'
--GROUP BY npi, drug_name, total_claim_count
ORDER BY total_claims DESC)

SELECT SUM(total_claims)
FROM ggg
WHERE npi = '1457685976';




