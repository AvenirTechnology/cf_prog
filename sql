drop table temp_cf_acc;

create table temp_cf_acc (
date date,
org_id bigint,
account_id bigint,
mvmax bigint,
mvmin bigint,
worst bigint,
imabsolute bigint,
imactual bigint,
vmactual bigint
);

\copy temp_cf_acc from cf_acc (HEADER true, FORMAT 'csv');

drop table temp_cf_ins;

create table temp_cf_ins (
date date,
acc integer,
org integer,
inst integer,
del integer,
rec integer,
net integer,
max bigint,
min bigint,
im bigint,
vma bigint
);

\copy temp_cf_ins from cf_inst (HEADER true, FORMAT 'csv');


drop table temp_cf_pml;

create table temp_cf_pml (
date date,
max_pml bigint,
pml bigint
);

\copy temp_cf_pml from cf_pml (HEADER true, FORMAT 'csv');


drop table temp_cf_sum;

create table temp_cf_sum (
date date,
org integer,
acc integer,
max bigint,
min bigint,
mkt_worst bigint,
org_worst bigint,
net_worst bigint,
im bigint,
vim bigint,
vma bigint,
acc_worst bigint,
acc_im bigint,
acc_vma bigint,
org_pml bigint,
mkt_pml bigint
);

\copy temp_cf_sum from cf_sum (HEADER true, FORMAT 'csv');

drop table temp_cf_acc1;

create table temp_cf_acc1 (
date date,
org integer,
inst integer,
max bigint,
min bigint,
worst bigint,
im bigint,
vim bigint,
vma bigint
);

\copy temp_cf_acc1 from cf_acc1 (HEADER true, FORMAT 'csv');
