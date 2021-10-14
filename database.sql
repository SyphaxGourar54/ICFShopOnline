-- create the database
create database ShopOnlineICF; 
use ShopOnlineICF; 

--create table of categories
create table category(
code_cat int primary key identity(1, 1), 
title_cat nvarchar(60) not null, 
desc_cat nvarchar(200) not null, 
); 

--create table of subcategories
create table subcategory(
code_scat int primary key identity(1, 1), 
code_cat int not null,
title_scat nvarchar(60) not null, 
desc_scat nvarchar(200) not null, 
code_scat_father int
); 


alter table subcategory 
add constraint fk_cat_scat
foreign key (code_cat)
references category(code_cat); 

alter table subcategory
add constraint fk_fscat_sscat
foreign key(code_scat_father)
references subcategory(code_scat); 

--create table of products
create table product(
code_prdt int primary key identity(1, 1), 
code_cat int not null,
code_scat int, 
title_prdt nvarchar(70) not null, 
price_prdt money not null,
available bit not null, 
desc_prdt nvarchar(300), 
mark_prdt nvarchar(100), 
); 

alter table product
add constraint fk_prdt_cat
foreign key(code_cat) 
references category(code_cat); 

alter table product 
add constraint fk_prdt_subcat
foreign key(code_scat) 
references subcategory(code_scat); 

--create table of images of the products
create table images(
code_img int primary key identity(1, 1), 
title_img nvarchar(200) not null, 
img image, 
code_prdt int not null, 
); 

alter table images
add constraint fk_prdt_img
foreign key(code_prdt)
references product(code_prdt); 

-- create table of clients
create table dbo.[client](
code_clt int primary key identity(1, 1), 
email_clt varchar(70) not null,
password_clt binary(64) not null, 
fullname_clt nvarchar(60),

country_clt nvarchar(40), 
city_clt nvarchar(40), 
street_clt nvarchar(70), 
building_clt nvarchar(120), 
codepostal_clt nvarchar(20),
);

--create procedure to add a client and hash his password
go
alter proc dbo.add_client
	@email_clt varchar(70),
	@password_clt nvarchar(50), 
	@fullname_clt nvarchar(60) = null,
	@country_clt nvarchar(40) = null, 
	@city_clt nvarchar(40) = null, 
	@street_clt nvarchar(70) = null, 
	@building_clt nvarchar(120) = null, 
	@codepostal_clt nvarchar(20) = null,
	@responseMessage NVARCHAR(250) OUTPUT

as 
begin
	SET NOCOUNT ON;
	DECLARE @salt UNIQUEIDENTIFIER=NEWID(); 
    BEGIN TRY

        INSERT INTO dbo.[client] (email_clt, password_clt, Salt, fullname_clt, country_clt, city_clt, street_clt, building_clt, codepostal_clt)
        VALUES(@email_clt, HASHBYTES('SHA2_512', @password_clt+CAST(@salt AS NVARCHAR(36))), @salt,  @fullname_clt, @country_clt, @city_clt, @street_clt, @building_clt, @codepostal_clt)

        SET @responseMessage='Success'

    END TRY
    BEGIN CATCH
        SET @responseMessage=ERROR_MESSAGE() 
    END CATCH
end

--alter client table to add salt
alter table client add
Salt UNIQUEIDENTIFIER; 




--testing the proc
------------------start testing------------------
go
DECLARE @responseMessageout NVARCHAR(250)
EXEC dbo.add_client
	@email_clt = 'Abderrahim.gourar54@gmail.com',
	@password_clt = '123pass', 
	@fullname_clt = 'Abderrahim Gourar' ,
	@country_clt = 'Morocco', 
	@city_clt = 'Marrakesh', 
	@street_clt = 'Mohammed VI', 
	@building_clt = 'ikamat assaadyin', 
	@codepostal_clt = '401267',
	@responseMessage = @responseMessageout OUTPUT

SELECT *
FROM client; 
--------------------end testing----------------------


--create the proc for login

go 
alter PROCEDURE dbo.cltLogin
    @email NVARCHAR(254),
    @password NVARCHAR(50),
    @responseMessage NVARCHAR(250)='' OUTPUT,
	@status int = 0 output
AS
BEGIN

    SET NOCOUNT ON

    DECLARE @userID INT

    IF EXISTS (SELECT TOP 1 code_clt FROM [dbo].[client] WHERE email_clt=@email)
    BEGIN
        SET @userID=(SELECT code_clt FROM [dbo].client WHERE email_clt=@email AND password_clt=HASHBYTES('SHA2_512', @password+CAST(Salt AS NVARCHAR(36))))

       IF(@userID IS NULL)
	   begin
           SET @responseMessage='Incorrect password'
		   set @status = 0;
		   end
       ELSE 
	   begin
           SET @responseMessage='User successfully logged in'
		   set @status = 1;
		   end
    END
    ELSE
	begin
       SET @responseMessage='Invalid login'
	   set @status = -1
	   end

END


---testing login proce
------------------------------------------------------------------------------
-------------start testing----------------------------------------------------
go
DECLARE	@responseMessage nvarchar(250); 
declare @status int;

EXEC	dbo.cltLogin
		@email = 'Abdeqrrahim.gourar54@gmail.com',
		@password = '123passs',
		@responseMessage = @responseMessage OUTPUT,
		@status = @status output

SELECT	@responseMessage as N'@responseMessage', cast(@status as nvarchar(10)) as N'@status'


-------------end testing---------------------------------------------------------
---------------------------------------------------------------------------------
	


--create table of promotions
create table promotions(
	id_prom int primary key identity(1,1), 
	code_prom nvarchar(20) not null,
	code_prdt int not null, 
	new_price money not null, 
	date_start date not null, 
	date_end date not null
); 

alter table promotions
add constraint prom_prdt_fk
foreign key(code_prdt)
references product(code_prdt); 


--create table of 'panier'
create table basket(
code_bask int primary key identity(1, 1), 
code_clt int not null, 
creation_date date not null
); 

alter table basket 
add constraint bask_clt_fk
foreign key(code_clt)
references client(code_clt); 



--//in case u wanna resume//--
--create table of productchoice--
create table productpick(
code_prdt int not null, 
code_bask int not null, 
qte_prdt int not null,
constraint pk primary key(code_prdt, code_bask)
); 

alter table productpick 
add constraint prdt_pk
foreign key(code_prdt)
references product(code_prdt); 

alter table productpick 
add constraint basket_pk 
foreign key(code_bask)
references basket(code_bask); 



--//create table command//--

create table p_order(
code_cmd int primary key identity(1, 1),
code_bask int not null, 
date_cmd date not null, 
total money , 
); 


alter table p_order
add constraint basket_fk
foreign key(code_bask)
references basket(code_bask); 



-- table of favorit items
create table favorits(
code_prdt int not null, 
code_clt int not null, 
dateofadd date, 
constraint pk_fav primary key(code_prdt, code_clt) 
); 

alter table favorits 
add constraint prdtfav_fk
foreign key(code_prdt)
references product(code_prdt);

alter table favorits 
add constraint clttfav_fk
foreign key(code_clt)
references client(code_clt);


