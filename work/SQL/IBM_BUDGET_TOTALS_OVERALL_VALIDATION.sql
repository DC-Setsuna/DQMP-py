-- Validate Budgets on SIMPLE TOTALS

with FNTotals(NODE_ID, YEAR, QUARTER, REVENUE_TYPE, BUDGET_AMOUNT) as
(
	-- Roadmaps
	select FN.NODE_ID, 
		F.YEAR, 
		F.QUARTER, 
		F.REVENUE_TYPE, 
		SUM(F.AMOUNT) as BUDGET_AMOUNT	
	from SCTID.IBM_FN_TO_BUDGET as FN
		inner join SCTID.IBM_FINANCIALS as F on (F.ID = FN.FINANCIALS_ID and F.DELETED = 0)
	where FN.DELETED = 0 
		and FN.PRIMARY_ASSIGNMENT = 1
--		and node_id in ('IGF_99_NA-CA_FSE15','IGF_04_NA-CA_0019')		
	group by FN.NODE_ID, F.YEAR, F.QUARTER, REVENUE_TYPE
)

select
	case when NVL(TRIM(F.NODE_ID), '') != NVL(TRIM(T.NODE_ID),'') then CONCAT(CONCAT(NVL(TRIM(F.NODE_ID), ''), ' != '), NVL(TRIM(T.NODE_ID), '')) 
		else '* ' || F.NODE_ID end as NODE_ID,
	case when T.BUDGET_AMOUNT IS NULL then CONCAT(NVL(F.BUDGET_AMOUNT, 0), ' != ')
		when  NVL(F.BUDGET_AMOUNT, 0) != NVL(T.BUDGET_AMOUNT, 0) then CONCAT(CONCAT(CONCAT(NVL(F.BUDGET_AMOUNT, 0), ' != '), NVL(T.BUDGET_AMOUNT, 0)), ' ... ' || (NVL(F.BUDGET_AMOUNT, 0) - NVL(T.BUDGET_AMOUNT, 0))) 
		else '* ' || F.BUDGET_AMOUNT end as BUDGET_AMOUNT,
	'* ' || F.YEAR as YEAR,
	'* ' || F.QUARTER as QUARTER,
	'* ' || F.REVENUE_TYPE as REVENUE_TYPE
	from FNTotals as F
	
	-- Join to FORECAST_TOTALS to see what amounts are out but only on the Grand Total row
	left join SCTID.IBM_FORECAST_TOTALS as T on (F.NODE_ID = T.NODE_ID and F.REVENUE_TYPE = T.REVENUE_TYPE and T.DELETED = 0 
		and T.BREAKOUT_1_KEY='TOTAL' and T.BREAKOUT_2_KEY='TOTAL' and T.BREAKOUT_3_KEY='TOTAL'
	)
	inner join SCTID.IBM_FDIM_DATE FD on (FD.ID = T.FDIM_DATE_ID and F.YEAR = FD.CAL_YEAR and F.QUARTER = FD.CAL_QUARTER and FD.DELETED = 0)
	where (
		(T.NODE_ID is null and (F.BUDGET_AMOUNT) != 0)
		or F.BUDGET_AMOUNT != T.BUDGET_AMOUNT
	)
--	and node_id in ('IGF_99_NA-CA_FSE15','IGF_04_NA-CA_0019')		
--	order by REVENUE_TYPE, FDIM_DATE_ID, NODE_ID 
for read only with UR;