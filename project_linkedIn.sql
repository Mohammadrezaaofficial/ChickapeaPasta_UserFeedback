select * from chickapea_pasta_customer;

-- Q1. What % of respondents bought Chickapea after trying the sample?
select avg(Bought_After_sample)*100 as mean_bought_after_sample
from chickapea_pasta_customer;

-- Q2. What is the overall Purchase Intent rate?
select avg(Purchase_Intent)*100 as mean_Purchase_Intent
from chickapea_pasta_customer;

select
sum(Purchase_Intent = 0) as sum_Purchase_Intent_0,
sum(Purchase_Intent = 1) as sum_Purchase_Intent_1
from chickapea_pasta_customer;

-- Q3. What is the overall NPS and the shares of Promoters / Passives / Detractors?
select avg(cast(Pasta_Recommendation_Scale as decimal(10,2))) /10 * 100  As overall_nps_rating_percent
from chickapea_pasta_customer;
-- CAST() converts a value from one data type to another. means: “treat Pasta_Recommendation_Scale as a number with up to 10 digits total and 2 decimal places.
select avg(cast(Pasta_Recommendation_Scale as decimal(10,2))>= 9) *100 As promoters_percent
from chickapea_pasta_customer;

select avg(cast(Pasta_Recommendation_Scale as decimal(10,2))<=6) *100 As detractors_percent
from chickapea_pasta_customer;

select 
(1 - avg(cast(Pasta_Recommendation_Scale as decimal(10,2))>= 9) - avg(cast(Pasta_Recommendation_Scale as decimal(10,2))<=6) * 100)
from chickapea_pasta_customer;

-- Q4. Among buyers, what is the average number of boxes purchased?

select
Bought_After_sample,
avg(
case Pasta_Boxes
	when '1' then 1
	when '2-3' then 2.5
	when '4-5' then 4.5
	when 'More than 5' then 5.5
end
) as avg_boxes_for_buyers
from chickapea_pasta_customer
group by Bought_After_sample
order by Bought_After_sample;

-- Q5. What are the average taste and texture ratings?
select
  avg(Taste_Rate) as avg_taste_rating,
  avg(Texture_Rate) as avg_texture_rating
from chickapea_pasta_customer;

-- Q6. Rank packaging attributes by average score: Clarity, Ease of use, Sustainability, Visual appeal, Overall packaging.

select 
avg(Clarity_Packaging) as average_Clarity_rating,
avg(Ease_Packaging) as average_Ease_of_use_rating,
avg(Sustainability_Packaging) as average_Sustainability_rating,
avg(Visual_Packaging) as average_Visual_appeal_rating,
avg(Overall_Packaging) as average_Overall_packaging_rating
from chickapea_pasta_customer;

-- Q7. Compare Purchase Intent for women 25–34 vs men 25–34 and report the pp difference

select
  female_purchase_intent_rate,
  male_purchase_intent_rate,
  (female_purchase_intent_rate - male_purchase_intent_rate) * 100
    as difference_female_male
from (
  select
    avg(
      case
        when Gender = 'Female'
         and Age_Range in ('20-30', '31-40')
        then Purchase_Intent
      end
    ) as female_purchase_intent_rate,

    avg(
      case
        when Gender = 'Male'
         and Age_Range in ('20-30', '31-40')
        then Purchase_Intent
      end
    ) as male_purchase_intent_rate
  from chickapea_pasta_customer
) as rates;

-- Q8. What’s the lift in Purchase Intent for respondents with taste ≥ 4 vs < 4?

select 
high_Purchase_Intent * 100,
low_Purchase_Intent * 100,
(high_Purchase_Intent - low_Purchase_Intent) * 100 as difference
from (
select
	avg(case
    when Taste_Rate >= 4 
    then Purchase_Intent 
    end) as high_Purchase_Intent,
    
    avg(case
    when Taste_Rate < 4
    then Purchase_Intent
    end) as low_Purchase_Intent
    from chickapea_pasta_customer) as rates;  


-- Q9. Among those who had tried legume-based pasta before vs hadn’t, what is the trial→purchase conversion (% bought after sample)?

select 
tried_before_buy * 100,
not_tried_before_buy * 100
from (
select
	avg( 
	case 
	when Tried_Legume_Pasta = 1
	then Bought_After_sample
	end) as tried_before_buy,

	avg(
	case 
	when Tried_Legume_Pasta = 0
	then Bought_After_sample
	end) as not_tried_before_buy
from chickapea_pasta_customer
) as rates;


-- Q10. Which two Provinces have the highest NPS?

select
  Province,
  avg(CAST(Pasta_Recommendation_Scale as decimal(10,2))) as avg_nps
from chickapea_pasta_customer
group by Province
order by avg_nps desc
limit 2;


-- Q11. Which stores are most easily accessed among buyers vs non-buyers (top 3 per group)?

select
  Bought_After_sample,
  Easy_Access_Store,
  store_count
from (
  select
    Bought_After_sample,
    Easy_Access_Store,
    COUNT(*) as store_count,
    row_number() over (
      partition by Bought_After_sample
      order by COUNT(*) desc
    ) as store_rank
  from chickapea_pasta_customer
  where Bought_After_sample in (0, 1)
  group by Bought_After_sample, Easy_Access_Store
) as ranked_stores
where store_rank <= 3
order by Bought_After_sample desc, store_rank;


-- Q12. - Build a funnel with rates: Sampled → Bought → Plan monthly → Promoters. Then repeat for one high-opportunity segment you choose and identify the biggest drop-off.

select
  bought / total_sampled as sampled_to_bought,
  plan_monthly / bought as bought_to_plan_monthly,
  promoters / plan_monthly as plan_monthly_to_promoters
from (
  select
    COUNT(*) as total_sampled,

    SUM(case
          when Bought_After_sample = 1
          then 1 else 0
        end) as bought,

    SUM(case
          when Bought_After_sample = 1
          then 1 else 0
        end) as plan_monthly,

    SUM(case
          when CAST(Pasta_Recommendation_Scale AS DECIMAL(10,2)) >= 9
          then 1 else 0
        end) as promoters
  from chickapea_pasta_customer
) as funnel;


select
  bought_ht / total_high_taste as sampled_to_bought,
  plan_monthly_ht / bought_ht as bought_to_plan_monthly,
  promoters_ht / plan_monthly_ht as plan_monthly_to_promoters
from (
  select
    COUNT(*) as total_high_taste,

    SUM(case
          when Bought_After_sample = 1
          then 1 else 0
        end) as bought_ht,

    SUM(case
          when Bought_After_sample = 1
          then 1 else 0
        end) as plan_monthly_ht,

    SUM(case
          when CAST(Pasta_Recommendation_Scale as decimal(10,2)) >= 9
          then 1 else 0
        end) as promoters_ht
  from chickapea_pasta_customer
  where CAST(Taste_Rate as decimal(10,2)) >= 4
) as funnel_high_taste;

select
  1 - overall_bought_rate as biggest_dropoff_overall,
  1 - high_taste_bought_rate as biggest_dropoff_high_taste
from (
  select
    avg(case
          when Bought_After_sample = 1
          then 1 else 0
        end) as overall_bought_rate,

    avg(case
          when CAST(Taste_Rate as decimal(10,2)) >= 4
          then Bought_After_sample
        end) as high_taste_bought_rate
  from chickapea_pasta_customer
) as rates;

-- Q13. Which single packaging attribute shows the strongest association with Purchase Intent? Report the effect size (e.g., pp uplift or correlation) and give one recommended improvement.

select
  'Clarity_Packaging' as packaging_metric,
  Clarity_Packaging as rating,
  avg(Purchase_Intent) as avg_purchase_intent
from chickapea_pasta_customer
group by Clarity_Packaging

union all

select
  'Ease_Packaging' as packaging_metric,
  Ease_Packaging as rating,
  avg(Purchase_Intent) as avg_purchase_intent
from chickapea_pasta_customer
group by Ease_Packaging

union all

select
  'Sustainability_Packaging' as packaging_metric,
  Sustainability_Packaging as rating,
  avg(Purchase_Intent) as avg_purchase_intent
from chickapea_pasta_customer
group by Sustainability_Packaging

union all

select
  'Visual_Packaging' as packaging_metric,
  Visual_Packaging as rating,
  Avg(Purchase_Intent) as avg_purchase_intent
from chickapea_pasta_customer
group by Visual_Packaging

union all

select
  'Overall_Packaging' as packaging_metric,
  Overall_Packaging as rating,
  avg(Purchase_Intent) as avg_purchase_intent
from chickapea_pasta_customer
group by Overall_Packaging

order by packaging_metric, rating;