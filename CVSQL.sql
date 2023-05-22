/* Using Database AdventureWorksDW2020, table dbo.FactInternetSales 
Write a query that'll query Rention Cohort Analysis based on First time Customer Purchase in the period of Jan 2020 to Jan 2021*/ 
With ListOrder as
(
Select Distinct CustomerKey
, OrderDate
from FactInternetSales
), first_order as (
Select Distinct CustomerKey
, Min(OrderDate) as first_order_date
, FORMAT(Min(OrderDate),'yyyy-MM') as Cohort_first_order_date
From ListOrder
Group by CustomerKey
), Cohort_analysis as 
(
Select Distinct L.CustomerKey
, F.Cohort_first_order_date
, DATEDIFF(month,F.first_order_date,L.OrderDate) as Retention_month
From ListOrder as L
Join first_order as F
on L.CustomerKey = F.CustomerKey
)
Select * 
Into #temp_pvt1
From Cohort_analysis
Pivot 
(Count(CustomerKey) For Retention_month IN ([0],[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])) as p
Where Cohort_first_order_date >= '2020-01'
Order by Cohort_first_order_date DESC

Select * 
From #temp_pvt1
Order by Cohort_first_order_date DESC

/*  Từ bảng DimEmployee, 
tính tổng thời gian dài nhất mỗi phòng ban không tuyển dụng bất cứ ai (sử dụng cột HireDate) */ 
 
 WITH hirelist as (
select distinct DepartmentName,
HireDate
from [dbo].[DimEmployee]
) 
, cal_days AS (
SELECT distinct DepartmentName, 
HireDate, 
DATEDIFF(DAY, LAG(HireDate) OVER (PARTITION BY DepartmentName ORDER BY HireDate), HireDate) as DatediffHire 
FROM Hirelist
)

SELECT DepartmentName, MAX(DatediffHire)
FROM cal_days
GROUP BY DepartmentName;


/*Using Database AdventureWorksDW2020, table dbo.FactInternetSales
Write a query that'll query to implement RFM analysis into serveral segmentation like */

With customersales as
(
Select Customerkey
, Count(Distinct SalesOrderNumber) as number_of_order -- F
, SUM(SalesAmount) as total_sale -- M
, Max(OrderDate) as most_recent_order -- R
, DATEDIFF(day,Max(OrderDate),(Select Max(orderDate) from FactInternetSales)) as recency
From Factinternetsales
Group by CustomerKey
), RFM_scoring as
(
Select CustomerKey
, NTILE (4) Over (Order by Recency DESC) as rfm_recency
, NTILE (4) Over (Order by number_of_order) as rfm_frequency
, NTILE (4) Over (Order by total_sale) as rfm_money
From customersales
), RFM_score as
(
Select CustomerKey
, CONCAT(rfm_recency,rfm_frequency,rfm_money) as final_score
From RFM_scoring
), RFM_segmentation as
(
Select Customerkey
, final_score
, Case
When final_score like '1__' then 'Lost customer'
When final_score like '[3,4][3,4][1,2]' then 'promising'
When final_score like '[3,4][3,4][3,4]' then 'loyal'
When final_score like '_[1,2]4' then 'big spender'
When final_score Like '[3,4][1,2]_' then 'new customer'
When final_score Like '2__' then 'potential churn'
End as customersegmentation
From RFM_score
) Select 
Count(CustomerKey) as numberofcust
, customersegmentation
From RFM_segmentation
Group by customersegmentation

/* Define a function that Calculate Age until Today 
Input parameter is the Date of Birth (DOB) and the Return value is Age Current.  
Noted that:  
If the DOB month is greater than the current month, or if the DOB month is the same as the current month but the DOB day is greater than the current day, then subtract 1 from the calculated age. 
Otherwise, no adjustment is made 
*/  

Create Function dbo.calculateage (@dob Date) 
Returns INT 
as begin 
	Declare @age INT; 
	Select @age = DATEDIFF(Year,@DOB,GETDATE()) -  
	(Case when month(@DOB) > month(getdate())  
	Or (month(@DOB) = month(getdate()) AND day(@dob) > day(getdate())) 
	then 1 else 0 END); 
	Return @age; 
	End; 

Select StudentId 
, DateOfBirth 
, dbo.calculateage(Dateofbirth) as age
from Students 



