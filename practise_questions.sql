-- Task 1. Create a New Book Record
insert into books(isbn,book_title,category,rental_price,status,author,publisher)
values('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');


-- Task 2: Update an Existing Member's Address
update members
set member_address='125 main st'
where member_id='C101';


-- Task 3: Delete a Record from the Issued Status Table
delete from issued_status
where issued_id='IS121';


-- Task 4: Retrieve All Books Issued by a Specific Employee
select * from issued_status
where issued_emp_id='E101';


-- Task 5: List Members Who Have Issued More Than One Book
-- list of members
select m.member_name,count(st.issued_book_name) as books_count
from members m 
join issued_status st on  m.member_id=st.issued_member_id
group by m.member_name
having count(st.issued_book_name)>1;

-- list of employees
select e.emp_name,count(issued_book_name) as book_count
from employees e
join issued_status st on e.emp_id=st.issued_emp_id
group by e.emp_name
having count(issued_book_name)>1;


-- Task 6:each book and total book_issued_cnt
with cte as(select b.book_title,count(*) as issued_count
from books b
join issued_status st on b.isbn=st.issued_book_isbn
where status='yes'
group by b.book_title)


-- Task 7.Retrieve All Books in a Specific Category:
select * from books 
where category='classic';


-- Task 8: Find Total Rental Income by Category:
select b.category,count(*) as issued_count,sum(b.rental_price) as total_income
from books b
join issued_status st on b.isbn=st.issued_book_isbn
group by b.category;


-- Task 9.List Members Who Registered in the Last 180 Days**:
insert into members(member_id,member_name,member_address,reg_date)
values
('C120','Jeff Bezoz','456 Washington DC','2025-08-14'),
('C121','Sam Altman','123 paris','2025-08-18'),
('C122','Elon Musk','142 new york','2025-08-12'),
('C123','Donald Zelesky','789 papaugini','2025-08-10');

select * from members
where reg_date>=curdate()-interval 180 DAY;


-- Task 10: List Employees with Their Branch Manager's Name and their branch details**:
select e.*,b.manager_id,e2.emp_name
from employees e 
join branch b on e.branch_id=b.branch_id
join employees e2 on b.manager_id=e2.emp_id;


-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold
select * from books
where rental_price>7;


-- Task 12: Retrieve the List of Books Not Yet Returned
select st.issued_book_name
from issued_status st
left join return_status rt on st.issued_id=rt.issued_id
where rt.return_id is null;

    
-- Task 13: Identify Members with Overdue Books
select m.member_name,b.book_title,ist.issued_date,curdate()-ist.issued_date as overdues
from issued_status ist
join members m on ist.issued_member_id=m.member_id
join books b on ist.issued_book_isbn=b.isbn
left join return_status rs on ist.issued_id=rs.issued_id
where rs.return_id is null and curdate()-ist.issued_date>=30;


-- Task 14: Update Book Status on Return
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

    SELECT issued_book_isbn,issued_book_name
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


-- Task 15: Branch Performance Report
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(DISTINCT ist.issued_id) AS books_issued,
    COUNT(rs.return_id) AS books_returned,
    COALESCE(SUM(bk.rental_price), 0) AS total_revenue
FROM 
    issued_status ist
LEFT JOIN 
    return_status rs ON ist.issued_id = rs.issued_id
JOIN 
    books bk ON ist.issued_book_isbn = bk.isbn
JOIN 
    employees e ON ist.issued_emp_id = e.emp_id
JOIN 
    branch b ON e.branch_id = b.branch_id
GROUP BY 
    b.branch_id,
    b.manager_id;


-- Task 16: active_members who have issued at least one book in the last 6 months.
select issued_member_id
from issued_status
where issued_date>curdate()-'6 month';


-- Task 17: Find Employees with the Most Book Issues Processed
select e.emp_name,b.branch_id,b.manager_id,count(ist.issued_id) as books_issued
from issued_status ist
join employees e on ist.issued_emp_id=e.emp_id
join branch b on e.branch_id=b.branch_id
group by e.emp_name,b.branch_id,b.manager_id;


-- Task 18: Identify Members Issuing High-Risk Books    
alter table return_status add column book_quality varchar(20);
update return_status
set book_quality='good'
where return_id in('RS101',
'RS102',
'RS103',
'RS104',
'RS105',
'RS106');

update return_status
set book_quality='damaged'
where return_id in('RS107',
'RS108',
'RS109',
'RS110',
'RS111',
'RS112');

update return_status
set book_quality='bad'
where return_id in ('RS113'
'RS114',
'RS115',
'RS116',
'RS117',
'RS118',
'RS119',
'RS120');

select m.member_name,count(ist.issued_id) as issued_count
from issued_status ist
left join return_status rs on ist.issued_id=rs.issued_id
join members m on ist.issued_member_id=m.member_id
where rs.book_quality in('damaged','bad')
group by m.member_name
having count(ist.issued_id)>=2;


-- Task 19: Stored Procedure
DELIMITER $$

CREATE PROCEDURE update_book_table(
    p_issued_id VARCHAR(10),
    p_issued_member_id VARCHAR(30),
    p_issued_book_isbn VARCHAR(50),
    p_issued_emp_id VARCHAR(10)
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


-- Task 20:overdue and fines
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
