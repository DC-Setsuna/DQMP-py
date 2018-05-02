-- Validate the NODE breakout Budget TOTALS
with ChildTotals(NODE_ID, FDIM_DATE_ID, REVENUE_TYPE, BUDGET_AMOUNT) as
(
	select T.NODE_ID, T.FDIM_DATE_ID, T.REVENUE_TYPE, T.BUDGET_AMOUNT as BUDGET_AMOUNT
		from SCTID.IBM_FORECAST_TOTALS as T
			--inner join SCTID.IBM_FDIM_DATE as FD on (FD.ID = T.FDIM_DATE_ID)
			where T.DELETED=0 and T.BREAKOUT_1_KEY='TOTAL' and T.BREAKOUT_2_KEY='TOTAL' and T.BREAKOUT_3_KEY='TOTAL'
			and BUDGET_AMOUNT is not null
)
, NODEBOTotals(NODE_ID, FDIM_DATE_ID, REVENUE_TYPE, child_node, BUDGET_AMOUNT) as
(
	select T.NODE_ID, T.FDIM_DATE_ID, T.REVENUE_TYPE, 
	case when breakout_indc=1 then BREAKOUT_1_VALUE
	    else BREAKOUT_2_VALUE 
	end as child_node,
     T.BUDGET_AMOUNT as BUDGET_AMOUNT
		from SCTID.IBM_FORECAST_TOTALS as T
			--inner join SCTID.IBM_FDIM_DATE as FD on (FD.ID = T.FDIM_DATE_ID)
			where T.DELETED=0 and (
			(T.BREAKOUT_1_KEY='NODEID' and (T.BREAKOUT_2_KEY='TOTAL' or T.BREAKOUT_2_KEY is null) and (T.BREAKOUT_3_KEY='TOTAL' or T.BREAKOUT_3_KEY is null)
            and breakout_indc=1 and breakout_group=1
            )
            or
            (T.BREAKOUT_2_KEY='NODEID' and (T.BREAKOUT_3_KEY='TOTAL' or T.BREAKOUT_3_KEY is null))
            and breakout_indc=2 and breakout_group=1
            )
            and BUDGET_AMOUNT is not null 
)
, ProblemTotals(NODE_ID, FDIM_DATE_ID, REVENUE_TYPE, BUDGET_AMOUNT) as
(
	select T.NODE_ID, T.FDIM_DATE_ID, T.REVENUE_TYPE,
		case when NBO.BUDGET_AMOUNT != T.BUDGET_AMOUNT then CONCAT(CONCAT(CONCAT(NBO.BUDGET_AMOUNT, ' != '), T.BUDGET_AMOUNT), ' ... ' || (T.BUDGET_AMOUNT - NBO.BUDGET_AMOUNT)) else '' end as BUDGET_AMOUNT
		from ChildTotals as T
		--check if there is a parent of this total with a node breakout
		inner join sctid.ibm_node_domain dom on dom.domain_value=T.node_id and dom.deleted=0
		inner join sctid.ibm_forecast_node fn on (dom.node_id=fn.id and fn.deleted=0 and (fn.default_breakout_1='NODEID' or fn.default_breakout_2='NODEID'))
        --join again the parents totals for this node
	    left join NODEBOTotals as NBO on (T.NODE_ID = NBO.child_node and NBO.FDIM_DATE_ID = T.FDIM_DATE_ID
			and NBO.REVENUE_TYPE = T.REVENUE_TYPE)
		where (
			(NBO.NODE_ID is null and T.BUDGET_AMOUNT != 0)
			or NBO.BUDGET_AMOUNT != T.BUDGET_AMOUNT
		)
)
select REVENUE_TYPE, FDIM_DATE_ID, NODE_ID, BUDGET_AMOUNT from ProblemTotals
	order by REVENUE_TYPE, FDIM_DATE_ID, NODE_ID 
for read only
with UR;
