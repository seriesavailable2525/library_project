CREATE TABLE branch (
branch_id varchar(10)primary key,
manager_id varchar(10),
branch_address varchar(30),
contact_no varchar(15)
);

SELECT * FROM branch

CREATE TABLE employees (
emp_id varchar(10)primary key,
emp_name varchar(30),
position varchar(30),
salary DECIMAL(10,2),
branch_id varchar(10),
FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
);

SELECT * FROM employees

CREATE TABLE members (
member_id varchar(10)primary key,
member_name varchar(30),
member_address varchar(30),
reg_date Date
);

SELECT * FROM members

CREATE TABLE books (
isbn varchar(50)primary key,
book_title varchar(80),
category varchar(35),
rental_price DECIMAL(10,2),
status varchar(10),
author varchar(30),
publisher varchar(30)
);

SELECT * FROM books

CREATE TABLE issued_status(
issued_id VARCHAR(10) PRIMARY KEY,-
issued_member_id VARCHAR(30),
issued_book_name VARCHAR(80),
issued_date DATE,
issued_book_isbn VARCHAR(50),
issued_emp_id VARCHAR(10),
FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id),
FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn)
);

SELECT * FROM issued_status;

CREATE TABLE return_status(
return_id VARCHAR(10)PRIMARY KEY,
issued_id VARCHAR(30),
return_book_name VARCHAR(80),
return_date DATE,
return_book_isbn VARCHAR(50)
);

SELECT * FROM return_status

---Q1.Create a New Book Record**
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books
(isbn,book_title,category,rental_price,status,author,publisher)
VALUES
('978-1-60129-456-2','To Kill a Mockingbird','Classic',6.00,'yes','Harper Lee','J.B Lippincott & Co.');

---Task 2: Update an Existing Member's Address
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103'

---Task 3: Delete a Record from the Issued Status Table
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE FROM issued_status
WHERE issued_id = 'IS121'

---Task 4: Retrieve All Books Issued by a Specific Employee
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';

---Task 5: List Members Who Have Issued More Than One Book**
-- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT issued_emp_id,COUNT(issued_id) as total_book_issued from issued_status
GROUP BY issued_emp_id
HAVING COUNT(issued_id)>1;

---CTAS
---Task 6: Create Summary Tables**: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt
CREATE TABLE book_issued_cnt AS
SELECT b.isbn, b.book_title, COUNT(ist.issued_id) AS issue_count
FROM issued_status as ist
JOIN books as b
ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;

---Task 7. **Retrieve All Books in a Specific Category:
SELECT * FROM books
WHERE category = 'Classic'

---Task 8: Find Total Rental Income by Category
SELECT category,SUM(b.rental_price),COUNT(*)
FROM issued_status as ist
JOIN
books as b
ON b.isbn = ist.issued_book_isbn
GROUP BY 1

---Task9:List Members Who Registered in the Last 180 Days
SELECT * FROM members
WHERE reg_date >=CURRENT_DATE - INTERVAL'180 days'

---10.List Employees with Their Branch Manager's Name and their branch details:
SELECT 
    e1.emp_id,
	e1.emp_name,
	e1.position,
	e1.salary,
	b.*,
	e2.emp_name as manager
FROM employees as e1
JOIN 
branch as b
ON e1.branch_id = b.branch_id
JOIN
employees as e2
ON e2.emp_id = b.manager_id

---Task 11.Create a Table of Books with Rental Price Above a Certain Threshold
CREATE TABLE expensive_books AS
SELECT * from books
WHERE rental_price = 7.00;

---Task 12: **Retrieve the List of Books Not Yet Returned
SELECT * FROM issued_status as ist
LEFT JOIN 
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL;

---Task 13: Identify Members with Overdue Books  
--Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.
SELECT 
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    -- rs.return_date,
    CURRENT_DATE - ist.issued_date as over_dues_days
FROM issued_status as ist
JOIN 
members as m
    ON m.member_id = ist.issued_member_id
JOIN 
books as bk
ON bk.isbn = ist.issued_book_isbn
LEFT JOIN 
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE 
    rs.return_date IS NULL
    AND
    (CURRENT_DATE - ist.issued_date) > 30
ORDER BY 1

---Task 14: Update Book Status on Return 
--Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);
    
BEGIN
    -- all your logic and code
    -- inserting into returns based on users input
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE,p_book_quality);

    SELECT 
        issued_book_isbn,
        issued_book_name
        INTO
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;
    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
    
END;
$$

-- Testing FUNCTION add_return_records

issued_id = IS135
ISBN = WHERE isbn = '978-0-307-58837-1'

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- calling function 
CALL add_return_records('RS138', 'IS135', 'Good');

-- calling function 
CALL add_return_records('RS148', 'IS140', 'Good');

---Task 15: Branch Performance Report
CREATE TABLE branch_reports
AS
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) as number_book_issued,
    COUNT(rs.return_id) as number_of_book_return,
    SUM(bk.rental_price) as total_revenue
FROM issued_status as ist
JOIN 
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
JOIN 
books as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY 1, 2;

SELECT * FROM branch_reports;

---Task 16: CTAS: Create a Table of Active Members
CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id IN (SELECT 
                        DISTINCT issued_member_id   
                    FROM issued_status
                    WHERE 
                        issued_date >= CURRENT_DATE - INTERVAL '2 month'
                    );

SELECT * FROM active_members;

---Task 17: Find Employees with the Most Book Issues Processed
SELECT 
    e.emp_name,
    b.*,
    COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY 1, 2


