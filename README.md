### **SQL PROJECT - LIBRARY MANAGEMENT SYSTEM**

![Library Image](https://previews.123rf.com/images/stocksbyrs/stocksbyrs2308/stocksbyrs230800285/210915615-an-illustration-of-a-library-with-bookshelves-and-a-clock-ai-generated.jpg)

#### **ER DIAGRAM**
![ER Diagram](https://github.com/parthpatoliya97/library_management_system_SQL/blob/main/ER-Diagram.png?raw=true)


#### **Topics covered in this project :-**
- CRUD operations on the database
- How to load the CSV file into the MySQL workbench 
- How to apply multi joins more than two or more tables
- How to visualize the dataset and deal with it
- Create stored procedures to automate the library management flow
- Fetching data from the tables 

#### **SOME PRACTISE QUESTIONS BASED ON DATASET :-**

#### 1. Create a New Book Record
```sql
insert into books(isbn,book_title,category,rental_price,status,author,publisher)
values('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
```


#### 2.Update an Existing Member's Address
- Update the address of a member with member_id = 'C101'.
```sql
UPDATE members
SET member_address = '125 main st'
WHERE member_id = 'C101';

```

#### 3.Delete a Record from the Issued Status Table
- Delete the record with issued_id = 'IS121' from issued_status.
```sql
DELETE FROM issued_status
WHERE issued_id = 'IS121';

```

#### 4.Retrieve All Books Issued by a Specific Employee
- Get all books issued by employee emp_id = 'E101'.

```sql
SELECT * 
FROM issued_status
WHERE issued_emp_id = 'E101';

```
#### 5.List Members Who Have Issued More Than One Book
- Find members who have issued more than one book.

```sql
SELECT m.member_name, COUNT(st.issued_book_name) AS books_count
FROM members m 
JOIN issued_status st ON m.member_id = st.issued_member_id
GROUP BY m.member_name
HAVING COUNT(st.issued_book_name) > 1;

```
- Also, find employees who have issued more than one book.

```sql
SELECT e.emp_name, COUNT(issued_book_name) AS book_count
FROM employees e
JOIN issued_status st ON e.emp_id = st.issued_emp_id
GROUP BY e.emp_name
HAVING COUNT(issued_book_name) > 1;

```

### 6.Create Summary Table
- Generate a summary table of books and their issued count.
```sql
WITH cte AS (
    SELECT b.book_title, COUNT(*) AS issued_count
    FROM books b
    JOIN issued_status st ON b.isbn = st.issued_book_isbn
    WHERE status = 'yes'
    GROUP BY b.book_title
)

```

### 7.Retrieve All Books in a Specific Category
- Get all books in the Classic category.
```sql
SELECT * 
FROM books 
WHERE category = 'classic';
```

### 8.Find Total Rental Income by Category
- Calculate total rental income grouped by category.
```sql
SELECT b.category, COUNT(*) AS issued_count, SUM(b.rental_price) AS total_income
FROM books b
JOIN issued_status st ON b.isbn = st.issued_book_isbn
GROUP BY b.category;
```

### 9.List Members Who Registered in the Last 180 Days
- Insert new members and then retrieve those who registered in the last 180 days.
```sql
INSERT INTO members (member_id, member_name, member_address, reg_date)
VALUES
('C120','Jeff Bezoz','456 Washington DC','2025-08-14'),
('C121','Sam Altman','123 paris','2025-08-18'),
('C122','Elon Musk','142 new york','2025-08-12'),
('C123','Donald Zelesky','789 papaugini','2025-08-10');

SELECT * 
FROM members
WHERE reg_date >= CURDATE() - INTERVAL 180 DAY;

```

### 10.List Employees with Their Branch Manager and Branch Details
- Show employees, their branch, and manager details.
```sql
SELECT e.*, b.manager_id, e2.emp_name AS manager_name
FROM employees e 
JOIN branch b ON e.branch_id = b.branch_id
JOIN employees e2 ON b.manager_id = e2.emp_id;

```

### 11.Books with Rental Price Above Threshold
- List books with rental_price > 7.
```sql
SELECT * 
FROM books
WHERE rental_price > 7;

```

### 12.Retrieve Books Not Yet Returned
- List all books that are issued but not returned.
```sql
SELECT st.issued_book_name
FROM issued_status st
LEFT JOIN return_status rt ON st.issued_id = rt.issued_id
WHERE rt.return_id IS NULL;

```

### 13.Identify Members with Overdue Books
- Find members with overdue books (more than 30 days).
```sql
SELECT m.member_name, b.book_title, ist.issued_date,
       CURDATE() - ist.issued_date AS overdues
FROM issued_status ist
JOIN members m ON ist.issued_member_id = m.member_id
JOIN books b ON ist.issued_book_isbn = b.isbn
LEFT JOIN return_status rs ON ist.issued_id = rs.issued_id
WHERE rs.return_id IS NULL 
  AND CURDATE() - ist.issued_date >= 30;

```

### 14.Stored Procedure – Update Book Status on Return
- Procedure to update book status when returned
- Insert the return book record into the return_status table
- Fetch details pf the return book by fetching the books's name and isbn number and stored it into the variable v_isbn,v_book_name
- Then update the book status in books table based on that isbn number by comparing it with the created v_isbn variable
- At last send the message to user that book is succesfully return with its name
```sql
DELIMITER $$

CREATE PROCEDURE update_return_status (
    IN p_return_id VARCHAR(10),
    IN p_issued_id VARCHAR(30)
)
BEGIN
    DECLARE v_isbn VARCHAR(50);
    DECLARE v_book_name VARCHAR(80);

    INSERT INTO return_status (return_id, issued_id, return_date)
    VALUES (p_return_id, p_issued_id, CURDATE());

    SELECT issued_book_isbn, issued_book_name
    INTO v_isbn, v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'Yes'
    WHERE isbn = v_isbn;

    SELECT CONCAT('Thank you for returning the book - ', v_book_name) AS message;
END$$

DELIMITER ;

CALL update_return_status('RS120', 'IS134');

```
### 15.Branch Performance Report
- Report showing books issued, returned, and revenue per branch.
```sql
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(DISTINCT ist.issued_id) AS books_issued,
    COUNT(rs.return_id) AS books_returned,
    COALESCE(SUM(bk.rental_price), 0) AS total_revenue
FROM issued_status ist
LEFT JOIN return_status rs ON ist.issued_id = rs.issued_id
JOIN books bk ON ist.issued_book_isbn = bk.isbn
JOIN employees e ON ist.issued_emp_id = e.emp_id
JOIN branch b ON e.branch_id = b.branch_id
GROUP BY b.branch_id, b.manager_id;

```

### 16.Create a Table of Active Members
- Create a table of active members who issued at least one book in the last 6 months.
```sql
CREATE TABLE active_members AS
SELECT issued_member_id
FROM issued_status
WHERE issued_date > CURDATE() - INTERVAL 6 MONTH;
```

### 17.Find Employees with Most Book Issues Processed
- Top 3 employees who processed the most issues.
```sql
SELECT e.emp_name, b.branch_id, b.manager_id, COUNT(ist.issued_id) AS books_issued
FROM issued_status ist
JOIN employees e ON ist.issued_emp_id = e.emp_id
JOIN branch b ON e.branch_id = b.branch_id
GROUP BY e.emp_name, b.branch_id, b.manager_id
ORDER BY books_issued DESC
LIMIT 3;

```

### 18.Identify Members Issuing High-Risk Books
- Members who issued damaged/bad books more than twice.
- insert the column book_quality in return_status table to filter out books based on its quality.
```sql
ALTER TABLE return_status
ADD COLUMN book_quality VARCHAR(20);

UPDATE return_status
SET book_quality = 'good'
WHERE return_id IN ('RS101','RS102','RS103','RS104','RS105','RS106');

UPDATE return_status
SET book_quality = 'damaged'
WHERE return_id IN ('RS107','RS108','RS109','RS110','RS111','RS112');

UPDATE return_status
SET book_quality = 'bad'
WHERE return_id IN ('RS113','RS114','RS115','RS116','RS117','RS118','RS119','RS120');

SELECT m.member_name, COUNT(ist.issued_id) AS issued_count
FROM issued_status ist
LEFT JOIN return_status rs ON ist.issued_id = rs.issued_id
JOIN members m ON ist.issued_member_id = m.member_id
WHERE rs.book_quality IN ('damaged','bad')
GROUP BY m.member_name
HAVING COUNT(ist.issued_id) >= 2;

```

### 19.Stored Procedure – Update Book Table
- Procedure to update book status when issued/returned
- When someone issued the the particular book this procedure first check the book status whether it is available or not
- If it is available then it issued to the customer
- If it is not available then sends the message that book is not available right now
- Also when customer returned the book it automatically update the book status "No" to "Yes" and "Yes" to "No" when book is issued to someone else
```sql
DELIMITER $$

CREATE PROCEDURE update_book_table(
    IN p_issued_id VARCHAR(10),
    IN p_issued_member_id VARCHAR(30),
    IN p_issued_book_isbn VARCHAR(50),
    IN p_issued_emp_id VARCHAR(10)
)
BEGIN
    DECLARE v_status VARCHAR(10);
    
    SELECT status INTO v_status FROM books WHERE isbn = p_issued_book_isbn;
    
    IF v_status = 'yes' THEN 
        INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES(p_issued_id, p_issued_member_id, CURDATE(), p_issued_book_isbn, p_issued_emp_id);
        
        UPDATE books
        SET status = 'no'
        WHERE isbn = p_issued_book_isbn;
    ELSE
        SELECT CONCAT('Sorry, the book you have requested is not available: ', p_issued_book_isbn) AS message;
    END IF;
END$$

DELIMITER ;

```

### 20.Overdue Books & Fines
- Create a table of overdue books with fine calculation.
- If overdue period is greater than 30 days then multiply it with 0.50 and return total overdue days
```sql
CREATE TABLE overdue_books_fines AS
SELECT 
    ist.issued_member_id,
    COUNT(ist.issued_id) AS number_of_overdue_books,
    SUM(CASE 
            WHEN DATEDIFF(CURDATE(), ist.issued_date) > 30 
            THEN DATEDIFF(CURDATE(), ist.issued_date) - 30 
            ELSE 0 
        END) AS total_overdue_days,
    SUM(CASE 
            WHEN DATEDIFF(CURDATE(), ist.issued_date) > 30 
            THEN (DATEDIFF(CURDATE(), ist.issued_date) - 30) * 0.50 
            ELSE 0 
        END) AS total_fines,
    COUNT(ist.issued_id) AS total_books_issued
FROM issued_status ist
LEFT JOIN return_status rs ON ist.issued_id = rs.issued_id
WHERE rs.return_date IS NULL 
  AND DATEDIFF(CURDATE(), ist.issued_date) > 30  
GROUP BY ist.issued_member_id;

```
