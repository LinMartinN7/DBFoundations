--*************************************************************************--
-- Title: Assignment06
-- Author: Lin Martin
-- Desc: This file demonstrates how to use Views
-- Change Log: When,Who,What
-- 2021-05-18, Lin Martin, Created File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment06DB_LinMartin')
	 Begin 
	  Alter Database [Assignment06DB_LinMartin] set Single_user With Rollback Immediate;
	  Drop Database Assignment06DB_LinMartin;
	 End
	Create Database Assignment06DB_LinMartin;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment06DB_LinMartin;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [mOney] NOT NULL
);
go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL -- New Column
,[ProductID] [int] NOT NULL
,[Count] [int] NOT NULL
);
go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, [Count])
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Union
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Union
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Order By 1, 2
go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From Categories;
go
Select * From Products;
go
Select * From Employees;
go
Select * From Inventories;
go

/********************************* Questions and Answers *********************************/
'NOTES------------------------------------------------------------------------------------ 
 1) You can use any name you like for you views, but be descriptive and consistent
 2) You can use your working code from assignment 5 for much of this assignment
 3) You must use the BASIC views for each table after they are created in Question 1
------------------------------------------------------------------------------------------'

-- Question 1 (5% pts): How can you create BACIC views to show data from each table in the database.
-- NOTES: 1) Do not use a *, list out each column!
--        2) Create one view per table!
--		  3) Use SchemaBinding to protect the views from being orphaned!

-- Categories View
Create View vCategories With Schemabinding 
AS
Select CategoryID, CategoryName From dbo.Categories;
Go

Select * From vCategories
Go

--Products View
Create View vProducts With Schemabinding
AS
Select ProductID, ProductName, CategoryID, UnitPrice From dbo.Products;
Go

Select * From vProducts
Go

--Employees View
Create View vEmployees With Schemabinding
AS
Select EmployeeID, Employees.EmployeeFirstName + ' ' + Employees.EmployeeLastName As 'EmployeeFullName', ManagerID From dbo.Employees;
Go

Select * From vEmployees
Go

--Inventories View
Create View vInventories With Schemabinding
AS
Select InventoryID, InventoryDate, EmployeeID, ProductID, [Count] From dbo.Inventories;
Go

Select * From vInventories
Go

-- Question 2 (5% pts): How can you set permissions, so that the public group CANNOT select data 
-- from each table, but can select data from each view?

Use Assignment06DB_LinMartin
Deny Select On Categories To Public;
	Grant Select On vCategories To Public;
Deny Select On Products To Public;
	Grant Select On vProducts To Public;
Deny Select On Employees To Public;
	Grant Select On vEmployees To Public;
Deny Select On Inventories To Public;
	Grant Select On vInventories To Public;
Go

-- Question 3 (10% pts): How can you create a view to show a list of Category and Product names, 
-- and the price of each product?
-- Order the result by the Category and Product!

-- Here is an example of some rows selected from the view:
-- CategoryName,ProductName,UnitPrice
-- Beverages,Chai,18.00
-- Beverages,Chang,19.00
-- Beverages,Chartreuse verte,18.00

Create or Alter View vProductsByCategories
As
Select Top 100000 CategoryName, ProductName, UnitPrice
	From dbo.Categories Inner Join dbo.Products
	On Products.CategoryID = Categories.CategoryID
	Order By CategoryName Asc, ProductName Asc;
Go

Select * From vProductsByCategories
Go

-- Question 4 (10% pts): How can you create a view to show a list of Product names 
-- and Inventory Counts on each Inventory Date?
-- Order the results by the Product, Date, and Count!

-- Here is an example of some rows selected from the view:
--ProductName,InventoryDate,Count
--Alice Mutton,2017-01-01,15
--Alice Mutton,2017-02-01,78
--Alice Mutton,2017-03-01,83

Create or Alter View vInventoriesByProductsByDates
As
Select Top 100000 ProductName, InventoryDate, [Count]
	From Products Inner Join Inventories
	On Products.ProductID = Inventories.ProductID
	Order By ProductName Asc, InventoryDate Asc, [Count] Asc;
Go

Select * From vInventoriesByProductsByDates
Go

-- Question 5 (10% pts): How can you create a view to show a list of Inventory Dates 
-- and the Employee that took the count?
-- Order the results by the Date and return only one row per date!

-- Here is an example of some rows selected from the view:
-- InventoryDate,EmployeeName
-- 2017-01-01,Steven Buchanan
-- 2017-02-01,Robert King
-- 2017-03-01,Anne Dodsworth

Create or Alter View vInventoriesByEmployeesByDates
As
Select Distinct Top 100000 InventoryDate, EmployeeFirstName + ' ' + EmployeeLastName As 'EmployeeName'
	From Inventories Inner Join	Employees
	On Inventories.EmployeeID = Employees.EmployeeID
	Order By InventoryDate Asc; 
Go

Select * From vInventoriesByEmployeesByDates
Go

-- Question 6 (10% pts): How can you create a view show a list of Categories, Products, 
-- and the Inventory Date and Count of each product?
-- Order the results by the Category, Product, Date, and Count!

-- Here is an example of some rows selected from the view:
-- CategoryName,ProductName,InventoryDate,Count
-- Beverages,Chai,2017-01-01,72
-- Beverages,Chai,2017-02-01,52
-- Beverages,Chai,2017-03-01,54

Create or Alter View vInventoriesByProductsByCategories
As
Select Top 100000 CategoryName, ProductName, InventoryDate, [Count]
	From Categories Inner Join Products
	On Categories.CategoryID = Products.CategoryID
	Inner Join Inventories
	On Products.ProductID = Inventories.ProductID
	Order By CategoryName Asc, ProductName Asc, InventoryDate Asc, [Count] Asc;
Go

Select * From vInventoriesByProductsByCategories
Go

-- Question 7 (10% pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the EMPLOYEE who took the count?
-- Order the results by the Inventory Date, Category, Product and Employee!

-- Here is an example of some rows selected from the view:
-- CategoryName,ProductName,InventoryDate,Count,EmployeeName
-- Beverages,Chai,2017-01-01,72,Steven Buchanan
-- Beverages,Chang,2017-01-01,46,Steven Buchanan
-- Beverages,Chartreuse verte,2017-01-01,61,Steven Buchanan

Create or Alter View vInventoriesByProductsByEmployees
As
Select Top 100000 CategoryName, ProductName, InventoryDate, [Count], EmployeeFirstName + ' ' + EmployeeLastName As EmployeeFullName
	From Categories Inner Join Products
	On Categories.CategoryID = Products.CategoryID
	Inner Join Inventories
	On Products.ProductID = Inventories.ProductID
	Inner Join Employees
	On Inventories.EmployeeID = Employees.EmployeeID
	Order By InventoryDate Asc, CategoryName Asc, ProductName Asc, EmployeeFirstName;
Go

Select * From vInventoriesByProductsByEmployees
Go

-- Question 8 (10% pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the Employee who took the count
-- for the Products 'Chai' and 'Chang'? 

-- Here is an example of some rows selected from the view:
-- CategoryName,ProductName,InventoryDate,Count,EmployeeName
-- Beverages,Chai,2017-01-01,72,Steven Buchanan
-- Beverages,Chang,2017-01-01,46,Steven Buchanan
-- Beverages,Chai,2017-02-01,52,Robert King

Create or Alter View vInventoriesForChaiAndChangByEmployees
As
Select Top 100000 CategoryName, ProductName, InventoryDate, [Count], EmployeeFirstName + ' ' + EmployeeLastName As 'EmployeeName'
	From Categories Inner Join Products
	On Categories.CategoryID = Products.CategoryID
	Inner Join Inventories
	On Products.ProductID = Inventories.ProductID
	Inner Join Employees
	On Inventories.EmployeeID = Employees.EmployeeID
	Where Inventories.ProductID In (Select ProductID From Products Where ProductName = 'Chai' or ProductName = 'Chang')
	Order By InventoryDate Asc, CategoryName Asc, ProductName Asc;
Go

Select * From vInventoriesForChaiAndChangByEmployees
Go

-- Question 9 (10% pts): How can you create a view to show a list of Employees and the Manager who manages them?
-- Order the results by the Manager's name!

-- Here is an example of some rows selected from the view:
-- Manager,Employee
-- Andrew Fuller,Andrew Fuller
-- Andrew Fuller,Janet Leverling
-- Andrew Fuller,Laura Callahan

Create or Alter View vEmployeesByManager
As
Select Top 100000 M.EmployeeFirstName + ' ' + M.EmployeeLastName As Manager,
		E.EmployeeFirstName + ' ' + E.EmployeeLastName As Employee		
	From Employees E Inner Join Employees M On M.EmployeeID = E.ManagerID
	Order By Manager Asc;
Go

Select * From vEmployeesByManager
Go

-- Question 10 (20% pts): How can you create one view to show all the data from all four 
-- BASIC Views?

-- Here is an example of some rows selected from the view:
-- CategoryID,CategoryName,ProductID,ProductName,UnitPrice,InventoryID,InventoryDate,Count,EmployeeID,Employee,Manager
-- 1,Beverages,1,Chai,18.00,1,2017-01-01,72,5,Steven Buchanan,Andrew Fuller
-- 1,Beverages,1,Chai,18.00,78,2017-02-01,52,7,Robert King,Steven Buchanan
-- 1,Beverages,1,Chai,18.00,155,2017-03-01,54,9,Anne Dodsworth,Steven Buchanan

Create or Alter View vInventoriesByProductsByCategoriesByEmployees
As
Select Top 100000 C.CategoryID, C.CategoryName, P.ProductID, P.ProductName, P.UnitPrice, I.InventoryID, I.InventoryDate, I.[Count], 
		E.EmployeeID, E.EmployeeFirstName + ' ' + E.EmployeeLastName As Employee, M.EmployeeFirstName + ' ' + M.EmployeeLastName As Manager
	From Categories C Inner Join Products P
	On C.CategoryID = P.CategoryID
	Inner Join Inventories I
	On P.ProductID = I.ProductID
	Inner Join Employees E
	On I.EmployeeID = E.EmployeeID
	Inner Join Employees M 
	On M.EmployeeID = E.ManagerID
	Order By C.CategoryID Asc, C.CategoryName Asc, P.ProductName Asc;
Go

Select * From vInventoriesByProductsByCategoriesByEmployees
Go

-- Test your Views (NOTE: You must change the names to match yours as needed!)
Select * From [dbo].[vCategories]
Select * From [dbo].[vProducts]
Select * From [dbo].[vInventories]
Select * From [dbo].[vEmployees]

Select * From [dbo].[vProductsByCategories]
Select * From [dbo].[vInventoriesByProductsByDates]
Select * From [dbo].[vInventoriesByEmployeesByDates]
Select * From [dbo].[vInventoriesByProductsByCategories]
Select * From [dbo].[vInventoriesByProductsByEmployees]
Select * From [dbo].[vInventoriesForChaiAndChangByEmployees]
Select * From [dbo].[vEmployeesByManager]
Select * From [dbo].[vInventoriesByProductsByCategoriesByEmployees]
/***************************************************************************************/