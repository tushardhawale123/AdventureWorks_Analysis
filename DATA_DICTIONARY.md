# AdventureWorks Data Dictionary

This data dictionary provides details about the AdventureWorks database schema, including tables, relationships, and record counts.

## Database Overview

The AdventureWorks database is organized into 5 main schemas:
- **HumanResources**: Employee data and organizational structure
- **Person**: Customer and contact information
- **Production**: Products, inventory, and manufacturing
- **Purchasing**: Vendors and purchase orders
- **Sales**: Customers, orders, and sales activities

## Schema Details

### Human Resources Schema

| Table Name | Description | Row Count |
|------------|-------------|-----------|
| Department | Company departments | 16 |
| Employee | Employee details | 290 |
| EmployeeDepartmentHistory | Historical record of employee department assignments | 296 |
| EmployeePayHistory | Employee pay rate history | 316 |
| JobCandidate | Job applicant details | 13 |
| Shift | Work shift schedules | 3 |

### Person Schema

| Table Name | Description | Row Count |
|------------|-------------|-----------|
| Address | Physical addresses | 19,614 |
| AddressType | Types of addresses (e.g., Home, Shipping) | 6 |
| BusinessEntity | Primary entity table | 20,777 |
| BusinessEntityAddress | Connects entities to addresses | 19,614 |
| BusinessEntityContact | Contact information for entities | 909 |
| ContactType | Types of contacts | 20 |
| CountryRegion | Country and region information | 238 |
| EmailAddress | Email addresses | 19,972 |
| Password | User passwords | 19,972 |
| Person | Personal information | 19,972 |
| PersonPhone | Phone numbers | 19,972 |
| PhoneNumberType | Types of phone numbers | 3 |
| StateProvince | States and provinces | 181 |

### Production Schema

| Table Name | Description | Row Count |
|------------|-------------|-----------|
| BillOfMaterials | Materials required to manufacture products | 2,679 |
| Culture | Cultural or language identifiers | 8 |
| Document | Product documentation | 13 |
| Illustration | Product illustrations | 5 |
| Location | Inventory locations | 14 |
| Product | Product information | 504 |
| ProductCategory | Product categories | 4 |
| ProductCostHistory | Historical product costs | 395 |
| ProductDescription | Product descriptions | 762 |
| ProductDocument | Links products to documents | 32 |
| ProductInventory | Product inventory quantities | 1,069 |
| ProductListPriceHistory | Historical product list prices | 395 |
| ProductModel | Product models | 128 |
| ProductModelIllustration | Links product models to illustrations | 7 |
| ProductModelProductDescriptionCulture | Product descriptions by culture | 762 |
| ProductPhoto | Product photos | 101 |
| ProductProductPhoto | Links products to photos | 504 |
| ProductReview | Customer product reviews | 4 |
| ProductSubcategory | Product subcategories | 37 |
| ScrapReason | Reasons for scrapping products | 16 |
| TransactionHistory | Product transaction history | 113,443 |
| TransactionHistoryArchive | Archived transaction history | 89,253 |
| UnitMeasure | Units of measure | 38 |
| WorkOrder | Manufacturing work orders | 72,591 |
| WorkOrderRouting | Manufacturing steps | 67,131 |

### Purchasing Schema

| Table Name | Description | Row Count |
|------------|-------------|-----------|
| ProductVendor | Products supplied by vendors | 460 |
| PurchaseOrderDetail | Purchase order line items | 8,845 |
| PurchaseOrderHeader | Purchase order headers | 4,012 |
| ShipMethod | Shipping methods | 5 |
| Vendor | Supplier information | 104 |

### Sales Schema

| Table Name | Description | Row Count |
|------------|-------------|-----------|
| CountryRegionCurrency | Currency used in countries/regions | 109 |
| CreditCard | Customer credit card information | 19,118 |
| Currency | Currency information | 105 |
| CurrencyRate | Currency exchange rates | 13,532 |
| Customer | Customer information | 19,820 |
| PersonCreditCard | Links people to credit cards | 19,118 |
| SalesOrderDetail | Sales order line items | 121,317 |
| SalesOrderHeader | Sales order headers | 31,465 |
| SalesOrderHeaderSalesReason | Sales order reasons | 27,647 |
| SalesPerson | Sales employee information | 17 |
| SalesPersonQuotaHistory | Sales quota history | 163 |
| SalesReason | Sales reason lookup table | 10 |
| SalesTaxRate | Tax rates by region | 29 |
| SalesTerritory | Sales territory information | 10 |
| SalesTerritoryHistory | Sales territory assignment history | 17 |
| ShoppingCartItem | Online shopping cart items | 3 |
| SpecialOffer | Special offers | 16 |
| SpecialOfferProduct | Products with special offers | 538 |
| Store | Store information | 701 |

## Key Entity Relationships

### Customer-Related Relationships
- Customer ← PersonID → Person
- Customer ← StoreID → Store
- Customer ← TerritoryID → SalesTerritory
- Customer → CustomerID ← SalesOrderHeader

### Sales-Related Relationships
- SalesOrderHeader ← CustomerID → Customer
- SalesOrderHeader ← SalesPersonID → SalesPerson
- SalesOrderHeader ← ShipMethodID → ShipMethod
- SalesOrderHeader ← TerritoryID → SalesTerritory
- SalesOrderHeader → SalesOrderID ← SalesOrderDetail
- SalesOrderDetail ← ProductID → Product
- SalesOrderDetail ← SpecialOfferID → SpecialOffer

### Product-Related Relationships
- Product ← ProductSubcategoryID → ProductSubcategory
- ProductSubcategory ← ProductCategoryID → ProductCategory
- Product ← ProductModelID → ProductModel
- Product → ProductID ← ProductInventory
- Product → ProductID ← WorkOrder

### HR-Related Relationships
- Employee ← BusinessEntityID → Person
- EmployeeDepartmentHistory ← BusinessEntityID → Employee
- EmployeeDepartmentHistory ← DepartmentID → Department
- EmployeeDepartmentHistory ← ShiftID → Shift

### Purchasing-Related Relationships
- PurchaseOrderHeader ← VendorID → Vendor
- PurchaseOrderHeader → PurchaseOrderID ← PurchaseOrderDetail
- PurchaseOrderDetail ← ProductID → Product