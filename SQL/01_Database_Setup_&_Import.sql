--                                      CREATING DATABASE AND TABLES 
         
CREATE DATABASE axon_mfg;
USE axon_mfg;

CREATE TABLE Dim_Operation (
Operation_Code VARCHAR(10) PRIMARY KEY,
Operation_Name VARCHAR(40),
Standard_Cost_Per_Hour INT,
Is_Automated VARCHAR(5)
);

CREATE TABLE Dim_Machine (
Machine_Code varchar(10) PRIMARY KEY,
Operation_Code varchar(10),
Operation_Name varchar(20),
Avg_Daily_Cost DECIMAL(10,2),
Machine_Type varchar(20),
Status varchar(10),
FOREIGN KEY (Operation_Code) REFERENCES Dim_Operation(Operation_Code)
);

CREATE TABLE Dim_Buyer (
Buyer_Id VARCHAR(10) PRIMARY KEY,
Buyer_Name VARCHAR(10),
Region VARCHAR(20),
Founded_Year INT,
Segment VARCHAR(20)
);

CREATE TABLE Dim_Customer (
Customer_Code VARCHAR(20) PRIMARY KEY,
Customer_Name VARCHAR(100),
Customer_Type VARCHAR(40),
City VARCHAR(20),
Active VARCHAR(3)
); 

CREATE TABLE dim_Employee (
    Employee_Code VARCHAR(10) PRIMARY KEY,
    Employee_Name VARCHAR(100),
    Department VARCHAR(30),
    Level VARCHAR(30)
);

CREATE TABLE dim_Department (
    Dept_ID VARCHAR(5) PRIMARY KEY,
    Dept_Name VARCHAR(50) UNIQUE,
    Category VARCHAR(30),
    Head_Count_Range VARCHAR(30),
    Floor VARCHAR(20)
);

CREATE TABLE dim_Date (
    Date DATE PRIMARY KEY,
    Day INT,
    Day_Name VARCHAR(15),
    Week_Num INT,
    Month_Num INT,
    Month_Name VARCHAR(15),
    Quarter VARCHAR(5),
    Year INT,
    Is_Weekend VARCHAR(3),
    Season VARCHAR(20)
);

CREATE TABLE Dim_Item (
Item_Code VARCHAR(20) PRIMARY KEY,
Item_Name VARCHAR(100),
Department_Name VARCHAR(20),
Item_Category VARCHAR(20),
FOREIGN KEY (Department_Name) REFERENCES Dim_Department(Dept_Name)
);

CREATE TABLE fact_Production (
    Doc_Num VARCHAR(20) PRIMARY KEY,
    Date_FK DATE,
    Buyer_ID VARCHAR(5),
    Customer_Code VARCHAR(10),
    Employee_Code VARCHAR(10),
    Machine_Code VARCHAR(10),
    Operation_Code VARCHAR(10),
    Dept_ID VARCHAR(5),
    Item_Code VARCHAR(30),
    Delivery_Status VARCHAR(10),
    Is_Repeat_Order VARCHAR(3),
    WO_Qty INT,
    Press_Qty INT,
    Processed_Qty INT,
    Produced_Qty INT,
    Rejected_Qty INT,
    Today_Manufactured_Qty INT,
    Total_Qty BIGINT,
    Total_Value DECIMAL(14,2),
    Per_Day_Machine_Cost DECIMAL(10,2),
    Rejection_Rate_Pct DECIMAL(10,2),
    Efficiency_Rate_Pct DECIMAL(10,2),
    Machine_Utilization_Pct DECIMAL(10,2),
    Cost_per_Unit DECIMAL(10,2),

    FOREIGN KEY (Date_FK) REFERENCES dim_Date(Date),
    FOREIGN KEY (Buyer_ID) REFERENCES dim_Buyer(Buyer_ID),
    FOREIGN KEY (Customer_Code) REFERENCES dim_Customer(Customer_Code),
    FOREIGN KEY (Employee_Code) REFERENCES dim_Employee(Employee_Code),
    FOREIGN KEY (Machine_Code) REFERENCES dim_Machine(Machine_Code),
    FOREIGN KEY (Operation_Code) REFERENCES dim_Operation(Operation_Code),
    FOREIGN KEY (Dept_ID) REFERENCES dim_Department(Dept_ID),
    FOREIGN KEY (Item_Code) REFERENCES dim_Item(Item_Code)
);

-- USE LOCAL DATA INFILE IF NOT LOCAL DATA IMPORT WIZARD -----------------------------------
LOAD DATA LOCAL INFILE 'your_csv_file_path.csv'
INTO TABLE axon_mfg.your_table_name
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;