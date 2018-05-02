--1.  If OO is BP - all roadmaps for all line items on this opportunity should have a channel of BP
--2.  If OO is NOT BP and LIO forecasting role is BP Rep - all roadmaps for the particular line item should have a channel of BP
--3.  If OO is NOT BP and LIO Brand version is IBM Digital Sales (IIS/Inside Sales are synonymous), and forecast role is Coverage - all roadmaps for the particular line item should have a channel of TeleCoverage
--4.  If OO is NOT BP and LIO Brand version is IBM Digital Sales (IIS/Inside Sales are synonymous), and forecast role is Brand, or Product or Solution - all roadmaps for the particular line item should have a channel of TeleSales
--5.  If OO is NOT BP and LIO is NOT IBM Digital Sales, and forecast role is NOT BP rep - all roadmaps for the particular line item should have a channel of Field
--**  If none of the rules apply then channel of field is used. 

select 	'sctid.ibm_roadmaps,' || TRIM(c.RM_ID) as TICKLE
	, c.*	
from (
	select 
		r.id "RM_ID",
		r.rli_id "RLI_ID", 		
		r.OPPORTUNITY_ID "OPP_ID",
		m_exist.CHANNEL_ID "EXISTING_CHANNEL_ID",
		(case
			when trim(nvl(opp_should.ASSIGNED_BP_ID, '')) <> '' then 'BUSPARTNER'
			when trim(nvl(opp_should.ASSIGNED_BP_ID, '')) = '' and trim(fn_should.FORECASTING_ROLE) = 'BUSPARTNER' then 'BUSPARTNER'
			when trim(nvl(opp_should.ASSIGNED_BP_ID, '')) = '' and trim(fn_should.BRAND_VERSION) in ('IBMDIGITAL', 'IIS') and trim(fn_should.FORECASTING_ROLE) = 'COVERAGE' then 'TELECOV'
			when trim(nvl(opp_should.ASSIGNED_BP_ID, '')) = '' and trim(fn_should.BRAND_VERSION) in ('IBMDIGITAL', 'IIS') and trim(fn_should.FORECASTING_ROLE) in ('BRAND', 'PRODUCT', 'SOLUTION') then 'TELE'
			when trim(nvl(opp_should.ASSIGNED_BP_ID, '')) = '' and trim(fn_should.BRAND_VERSION) NOT in ('IBMDIGITAL', 'IIS') and trim(fn_should.FORECASTING_ROLE) <> 'BUSPARTNER' then 'DIRECT'
			else 'DIRECT'
		end) "SHOULDBE_CHANNEL_ID",
		opp_should.ASSIGNED_BP_ID "SHOULDBE_ASSIGNED_BP_ID",
		rli_should.ASSIGNED_USER_ID "SHOULDBE_ASSIGNED_USER_ID",
		fn_should.ID "NODE_ID", 	
		fn_should.BRAND_VERSION "BRAND_VERSION",
--		m.FORECAST_BRAND_ID "m.BRAND_VERSION", 		
		fn_should.FORECASTING_ROLE "FORECASTING_ROLE",
--		m.FORECAST_ROLE_ID "m.FORECASTING_ROLE",
		fn_should.WORKSHEET_VERSION "WORKSHEET_VERSION",		
		nu_should.USER_TYPE "USER_TYPE",				
		fr.FDIM_MISC_ID "FDIM_MISC_ID",
		m_exist.ID "MISC_ID",  
		opp_should.DELETED "OPP_DELETED", 
		fr.DELETED "RM_DELETED",
		rli_should.DELETED "RLI_DELETED",
		m_exist.DELETED "MISC_DELETED",
		nu_should.DELETED "NU_DELETED",
		fn_should.DELETED "FN_DELETED",
		'' "EMPTY" 
	from sctid.ibm_roadmaps r
		join sctid.IBM_FDIM_ROADMAP ifr on (ifr.roadmap_id = r.id)
		join sctid.IBM_FORECAST_ROADMAP fr on (fr.id = r.id)
		
		-- Existing value based on IBM_FDIM_ROADMAP (result table)
		join sctid.IBM_FDIM_MISC m_exist on (fr.fdim_misc_id = m_exist.id)
		
		-- Should values
		join sctid.IBM_REVENUELINEITEMS rli_should on (rli_should.id = r.rli_id)
		join sme.opportunities opp_should on (opp_should.id = r.opportunity_id)		
		join sctid.IBM_NODE_USERS nu_should on (rli_should.assigned_user_id = nu_should.assigned_user_id)
		join sctid.ibm_forecast_node fn_should on (nu_should.node_id = fn_should.id and trim(nu_should.user_type) = 'OWNER' and trim(fn_should.worksheet_version) <> 'MANAGER')
		
	where r.DELETED = 0
		and fr.DELETED = 0
		and ifr.DELETED = 0
		and opp_should.DELETED = 0
		and rli_should.DELETED = 0
		and nu_should.DELETED = 0
		and fn_should.DELETED = 0
		and trim(nvl(fr.revenue_type, '')) <> ''
) as c
where 1=1
	and c.EXISTING_CHANNEL_ID != c.SHOULDBE_CHANNEL_ID
--order by c.RM_ID
for READ ONLY with UR;