-- make sure they all have the same deal size
-- 1) LIO gets aggregation for dealsize
-- 2) Non-LIO RM's in the same grouping/opportunity should have the same dealsize as the LIO in the same group.
-- 3) Managers referring to sellers should have the same dealsize as the LIO aggregation.

-- The query was broken up into 2 queries for performance reasons:
-- A. LIO Seller -> 2nd Seller
select 
	CONCAT(CONCAT(MISC_SELLER2.DEAL_SIZE_ID, ' != '), MISC_SELLER_LIO.DEAL_SIZE_ID) as "DEALSIZE (SELLER2 != LIO)",
	FDIM_SELLER_LIO.OPPORTUNITY_ID,
	FR_SELLER_LIO.REVENUE_TYPE,
	RLI_SELLER_LIO.LEVEL15, 
	DEAL_SELLER_LIO.GROUP_ID,
	FDIM_SELLER_LIO.RLI_ID as LIO_RLI_ID, 
	FDIM_SELLER2.RLI_ID as SELLER2_RLI_ID,
	FR_SELLER_LIO.ID as LIO_ROADMAP, 
	FR_SELLER2.ID as SELLER2_ROADMAP,
	MISC_SELLER_LIO.DEAL_SIZE_ID as LIO_DEALSIZE, 
	MISC_SELLER2.DEAL_SIZE_ID as SELLER2_DEALSIZE,
	MISC_SELLER_LIO.LIO_INDC as LIO_LIO_INDC,
	MISC_SELLER2.LIO_INDC as SELLER2_LIO_INDC,
	FR_SELLER_LIO.SELLER_AMOUNT_USD as LIO_SELLER_AMOUNT, 
	FR_SELLER2.SELLER_AMOUNT_USD as SELLER2_SELLER_AMOUNT
from SCTID.IBM_FORECAST_ROADMAP as FR_SELLER_LIO 
	inner join SCTID.IBM_FDIM_ROADMAP as FDIM_SELLER_LIO on (FDIM_SELLER_LIO.ID = FR_SELLER_LIO.FDIM_ROADMAP_ID and FDIM_SELLER_LIO.DELETED = 0) 
--  	inner join SCTID.IBM_FDIM_PRODUCT as PROD1 on PROD1.ID = FRM1.FDIM_PRODUCT_ID and PROD1.DELETED = 0 
	inner join SCTID.IBM_REVENUELINEITEMS as RLI_SELLER_LIO on (RLI_SELLER_LIO.ID = FDIM_SELLER_LIO.RLI_ID and RLI_SELLER_LIO.DELETED = 0) 
	inner join SCTID.IBM_FDIM_MISC as MISC_SELLER_LIO on (MISC_SELLER_LIO.ID = FR_SELLER_LIO.FDIM_MISC_ID and MISC_SELLER_LIO.DELETED = 0)
	inner join DATAOPS.FCST_DEAL_SIZE_ATTR as DEAL_SELLER_LIO on (RLI_SELLER_LIO.LEVEL15 = DEAL_SELLER_LIO.LEVEL15 and FR_SELLER_LIO.REVENUE_TYPE = DEAL_SELLER_LIO.REVENUE_TYPE)

	-- joins for 2nd seller roadmap which could be LIO or a NON-LIO. If LIO different RLI, NON-LIO can be in same RLI. 
	left join SCTID.IBM_FORECAST_ROADMAP as FR_SELLER2 on (FR_SELLER2.REVENUE_TYPE = FR_SELLER_LIO.REVENUE_TYPE and FR_SELLER2.DELETED = 0)
	left join SCTID.IBM_FDIM_ROADMAP as FDIM_SELLER2 on (FDIM_SELLER2.ID = FR_SELLER2.FDIM_ROADMAP_ID and FDIM_SELLER2.DELETED = 0)
--  	left join SCTID.IBM_FDIM_PRODUCT as PROD2 on PROD2.ID = FR_SELLER2.FDIM_PRODUCT_ID and PROD2.DELETED = 0
  	left join SCTID.IBM_REVENUELINEITEMS as RLI_SELLER2 on (RLI_SELLER2.ID = FDIM_SELLER2.RLI_ID and RLI_SELLER2.DELETED = 0)
  	left join SCTID.IBM_FDIM_MISC as MISC_SELLER2 on (MISC_SELLER2.ID = FR_SELLER2.FDIM_MISC_ID and MISC_SELLER2.DELETED = 0)
  	left join DATAOPS.FCST_DEAL_SIZE_ATTR as DEAL_SELLER2 on (RLI_SELLER2.LEVEL15 = DEAL_SELLER2.LEVEL15 and FR_SELLER2.REVENUE_TYPE = DEAL_SELLER2.REVENUE_TYPE)
where 
	-- Comparing the 2 seller roadmaps.
	FR_SELLER_LIO.FACT_TYPE = 1
	and FR_SELLER2.FACT_TYPE = 1
	and FR_SELLER_LIO.DELETED = 0
  	and FDIM_SELLER_LIO.OPPORTUNITY_ID = FDIM_SELLER2.OPPORTUNITY_ID
    and DEAL_SELLER_LIO.GROUP_ID = DEAL_SELLER2.GROUP_ID
    and MISC_SELLER_LIO.DEAL_SIZE_ID != MISC_SELLER2.DEAL_SIZE_ID
	-- Exclude all manager roadmaps from dealsize verification for sellers
	and NVL(FR_SELLER_LIO.MANAGER_ROADMAP_ID, '') = ''
	and NVL(FR_SELLER2.MANAGER_ROADMAP_ID, '') = ''    
	-- for the 2 seller roadmaps either they are both lios for different rlis in the same group
	-- which means the dealsize should be the same or if one is non-lio then there should be an lio
	-- for same rli with the same dealsize.
	-- ** this excludes case where there is an rli with an LIO rm which was excluded from processing
	and ((MISC_SELLER_LIO.LIO_INDC = 1 and MISC_SELLER2.LIO_INDC = 1)
		or (MISC_SELLER_LIO.LIO_INDC = 1 and MISC_SELLER2.LIO_INDC = 0 and FDIM_SELLER_LIO.RLI_ID = FDIM_SELLER2.RLI_ID))		
--order by FDIM_SELLER_LIO.OPPORTUNITY_ID, DEAL_SELLER_LIO.GROUP_ID
for read only with ur;