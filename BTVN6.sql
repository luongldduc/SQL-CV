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

-- R là chênh lệch giữa ngày mua gần nhất với ngày mới nhất của bộ dữ liệu
-- B2: đánh điểm RFM trên thang điểm 1 đến 4

/* Ex2. Từ bảng FactInventory, thống kê tổng số lượng hàng tồn kho (UnitBalance) đối với từng sản phẩm tại ngày cuối cùng của mỗi tháng.  
đồng thời tổng hợp lên tất cả sản phẩm trong tháng  
Kết quả trả ra gồm: Month (định dạng MM-yyyy), EndofMonthDate, EnglishProductName, TotalUnitsBalance 
*/ 
With month1 as 
(
Select Date
, Format(Date,'MM-yyyy') as Month
, FI.ProductKey
, FI.UnitsBalance
, DP.EnglishProductName
From FactProductInventory as FI
Left join DimProduct as DP
on FI.productkey = DP.productkey
) 
Select month
, EnglishProductName
, Sum(unitsBalance) as so_luong_ton_kho
From month1
Group by
ROLLUP (month,EnglishProductName)


 

/* Ex3. Từ bảng DimEmployee,  
tính tổng thời gian dài nhất mỗi phòng ban không tuyển dụng bất cứ ai (sử dụng cột HireDate)  
*/ 

Select HireDate
, ROW_NUMBER () over (Order by HireDate) as DateKey
INTO #Temp
From DimEmployee 

Select Max(DATEDIFF(day,T2.HireDate,T1.HireDate))
From #Temp as T1
Join #Temp as T2
on T1.DateKey-1 = T2.DateKey

Select HireDate
, DepartmentName
, ROW_NUMBER () Over (Partition by DepartmentName Order by HireDate) as empkey
INTO #tempEmp
From DimEmployee

With date_diff as 
(
Select DateDiff(day,T1.HireDate,T2.HireDate) as date_diff
, T1.DepartmentName
From #tempEmp as T1
Left join #tempEmp as T2
on T1.empkey = T2.empkey-1
and T1.DepartmentName = T2.DepartmentName
) Select Max(date_diff) as max_date
, DepartmentName
from date_diff 
Group by DepartmentName


-- Bài chữa 2
With EOFM as 
(
Select Format(DATEFROMPARTS(Year(Date), Month(date),'01'),'MM-yyyy') as yearmonth
, Max(Date) as Endofmonthdate
, EnglishProductName
, SUM(UnitsBalance) as UB
From FactProductInventory as FDI
Left join DimProduct as DP
on FDI.Productkey = DP.ProductKey
Group by Year(date), Month(date), EnglishProductName 
) 
Select yearmonth,EnglishProductName, Endofmonthdate , SUM(UB)
From EOFM
Group by Grouping sets (
( yearmonth,EnglishProductName, Endofmonthdate),
(yearmonth, Endofmonthdate)
)



-- Bài chữa 3

With hire_list as 
( 
Select Distinct DepartmentName
, HireDate
From DimEmployee 
)  --,Cal_day as 

Select Distinct DepartmentName
, HireDate
, Lag(hireDate) over (Partition by DepartmentName Order by HireDate)
From HireList