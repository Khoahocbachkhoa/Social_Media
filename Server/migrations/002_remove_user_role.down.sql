-- role không cần thiết, phiên bản ban đầu thiết kế chỉ cần user, chưa cần admin
alter table users
drop column if exists role;