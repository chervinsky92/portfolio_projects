-- Data cleaning: Nashville Housing data
-----------------------------------------------------------------------------------------
-- Examine data
SELECT TOP 100 *
FROM Portfolio.dbo.nashville_housing;

-----------------------------------------------------------------------------------------
-- Convert DATETIME (SaleDate) to DATE (SaleDateConverted)
SELECT SaleDate,
	CAST(SaleDate AS DATE)
FROM Portfolio.dbo.nashville_housing;

-- Create new column (SaleDateConverted) and insert values
ALTER TABLE nashville_housing
ADD SaleDateConverted DATE;

UPDATE Portfolio.dbo.nashville_housing
SET SaleDateConverted = CAST(SaleDate AS DATE);

-- Check
SELECT SaleDate, SaleDateConverted
FROM Portfolio.dbo.nashville_housing;

-----------------------------------------------------------------------------------------
-- Fix PropertyAddress where value is NULL
SELECT *
FROM Portfolio.dbo.nashville_housing
WHERE PropertyAddress IS NULL;

-- Using a subquery to confirm that ParcelID column can be used to identify correct PropertyAddress for NULL values
SELECT *
FROM Portfolio.dbo.nashville_housing
WHERE ParcelID IN (
	SELECT ParcelID
	FROM Portfolio.dbo.nashville_housing
	WHERE PropertyAddress IS NULL);

-- Use self-join and ISNULL function to connect each NULL value to the right address
-- Table a will have NULL value, Table b will provide proper address value from matching ParcelID
SELECT a.ParcelID, a.PropertyAddress, 
	b.ParcelID, b.PropertyAddress,
	ISNULL(a.PropertyAddress, b.PropertyAddress) AS PropertyAddressFixed
FROM Portfolio.dbo.nashville_housing a
JOIN Portfolio.dbo.nashville_housing b
	ON a.ParcelID = b.ParcelID
		AND a.[UniqueID ]!= b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

-- Update table
UPDATE a 
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio.dbo.nashville_housing a
JOIN Portfolio.dbo.nashville_housing b
	ON a.ParcelID = b.ParcelID
		AND a.[UniqueID ] != b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

-- Make sure NULL values are gone
SELECT *
FROM Portfolio.dbo.nashville_housing
WHERE PropertyAddress IS NULL;

-----------------------------------------------------------------------------------------
-- Separate PropertyAddress into Address and City columns to make data more usable

-- PropertyAddress: a single comma separates Address from City (Address, City)
SELECT PropertyAddress
FROM Portfolio.dbo.nashville_housing;

-- Extract Address and City fields from PropertyAddress
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
	RIGHT(PropertyAddress, LEN(PropertyAddress) - CHARINDEX(',', PropertyAddress) - 1) AS City
FROM Portfolio.dbo.nashville_housing

-- Create new columns (Address, City) and insert values
ALTER TABLE nashville_housing
ADD Address NVARCHAR(255);

UPDATE Portfolio.dbo.nashville_housing
SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

ALTER TABLE nashville_housing
ADD City NVARCHAR(255);

UPDATE Portfolio.dbo.nashville_housing
SET City = RIGHT(PropertyAddress, LEN(PropertyAddress) - CHARINDEX(',', PropertyAddress) - 1);

-- Check
SELECT *
FROM Portfolio.dbo.nashville_housing;

-----------------------------------------------------------------------------------------
-- Extract address fields from OwnerAddress (Address, City, State)
-- PARSENAME works with periods (not commas)
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM Portfolio.dbo.nashville_housing
WHERE OwnerAddress IS NOT NULL;

-- Create columns: AddressOwner, CityOwner, StateOwner and insert values
ALTER TABLE Portfolio.dbo.nashville_housing
ADD AddressOwner NVARCHAR(255);

UPDATE Portfolio.dbo.nashville_housing
SET AddressOwner = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

ALTER TABLE Portfolio.dbo.nashville_housing
ADD CityOwner NVARCHAR(255);

UPDATE Portfolio.dbo.nashville_housing
SET CityOwner = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

ALTER TABLE Portfolio.dbo.nashville_housing
ADD StateOwner NVARCHAR(255);

UPDATE Portfolio.dbo.nashville_housing
SET StateOwner = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Check
SELECT * 
FROM Portfolio.dbo.nashville_housing 
WHERE OwnerAddress IS NOT NULL;

-----------------------------------------------------------------------------------------
-- SoldAsVacant field: change values from Y/N -> Yes/No

-- Using DISTINCT, we find the range of values ['Yes', 'Y', 'No', 'N']
SELECT DISTINCT(SoldAsVacant)
FROM Portfolio.dbo.nashville_housing

-- Use CASE statement to create a column with Y/N values
SELECT SoldAsVacant,
	CASE 
		WHEN SoldAsVacant IN ('Yes', 'Y') THEN 'Yes'
		ELSE 'No'
	END AS SoldAsVacantFix
FROM Portfolio.dbo.nashville_housing

-- Update SoldAsVacant column values
UPDATE Portfolio.dbo.nashville_housing
SET SoldAsVacant = 
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END;

-- Check
SELECT SoldAsVacant
FROM Portfolio.dbo.nashville_housing;

SELECT DISTINCT(SoldAsVacant)
FROM Portfolio.dbo.nashville_housing;

-----------------------------------------------------------------------------------------
-- Remove duplicates

SELECT *
FROM Portfolio.dbo.nashville_housing;

-- row_number will have a value that represents how many copies of data exist for each set of values (ParcelId, PropertyAddress, SalePrice, SaleDate, LegalReference)
-- row_number > 1 represents a duplicate
SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
			     PropertyAddress,
			     SalePrice,
			     SaleDate,
			     LegalReference
		ORDER BY UniqueID) AS row_number
FROM Portfolio.dbo.nashville_housing
ORDER BY ParcelID;

-- Use CTE to display duplicates
WITH RowNum AS (
SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
			     PropertyAddress,
			     SalePrice,
			     SaleDate,
			     LegalReference
		ORDER BY UniqueID) AS row_number
FROM Portfolio.dbo.nashville_housing
)
SELECT *
FROM RowNum
WHERE row_number > 1;

-- Delete duplicates
WITH RowNum AS (
SELECT *,
	ROW_NUMBER() OVER (
	 	PARTITION BY ParcelID,
			     PropertyAddress,
			     SalePrice,
			     SaleDate,
			     LegalReference
		ORDER BY UniqueID) AS row_number
FROM Portfolio.dbo.nashville_housing
)
DELETE
FROM RowNum
WHERE row_number > 1;

-- Make sure all duplicates are deleted
WITH RowNum AS (
SELECT *,
	ROW_NUMBER() OVER (
 		PARTITION BY ParcelID,
			     PropertyAddress,
			     SalePrice,
			     SaleDate,
			     LegalReference
	 	ORDER BY UniqueID) AS row_number
FROM Portfolio.dbo.nashville_housing
)
SELECT *
FROM RowNum
WHERE row_number > 1;

-----------------------------------------------------------------------------------------
-- Remove columns that are no longer needed
SELECT *
FROM Portfolio.dbo.nashville_housing;

ALTER TABLE Portfolio.dbo.nashville_housing
DROP COLUMN SaleDate, PropertyAddress, OwnerAddress;
