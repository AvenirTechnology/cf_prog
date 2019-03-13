-- cf_account

delete from cf_account;

INSERT INTO cf_account(
id,org_id,account_id,date,mvmax,mvmin,worst,imabsolute,imactual,vmactual,
state,modal,reason,version,created,changed
)
SELECT
nextval('cf_account_id_seq'),
org_id,
account_id,
date,
mvmax,
mvmin,
worst,
imabsolute,
imactual,
vmactual,
4,0,0,1,now(),now()
FROM temp_cf_acc;


-- cf_instrument

delete from cf_instrument;

INSERT INTO cf_instrument(
    id,
    account_id,
    org_id,
    instrument_id,
    date,
    deliver,
    receive,
    net,
    mvmax,
    mvmin,
    imabsolute,
    vmactual,
    state,modal,reason,version,created,changed
)
SELECT
    nextval('cf_instrument_id_seq'),
    acc,
    org,
    inst,
    date,
    del,
    rec,
    net,
    max,
    min,
    im,
    vma,
    4,0,0,1,now(),now()
FROM
    temp_cf_ins;


-- cf_org_account

delete from cf_org_account;

INSERT INTO cf_org_account(
    id,
    org_id,
    instrument_id,
    date,
    mvmax,
    mvmin,
    worst,
    imabsolute,
    imactual,
    vmactual,
    state,modal,reason,version,created,changed
)
SELECT
    nextval('cf_org_account_id_seq'),
    org,
    inst,
    date,
    max,
    min,
    worst,
    im,
    vim,
    vma,
    4,0,0,1,now(),now()
FROM
    temp_cf_acc1;

-- cf_pml

delete from cf_pml;

INSERT INTO cf_pml(
    id,
    date,
    maxpml,
    pml,
    state,modal,reason,version,created,changed
)
SELECT
    nextval('cf_pml_id_seq'),
    date,
    max_pml,
    pml,
    4,0,0,1,now(),now()
FROM
    temp_cf_pml;


-- cf_summary

delete from cf_summary;

INSERT INTO cf_summary(
    id,
    org_id,
    account_id,
    date,
    networst,
    mvmax,
    mvmin,
    im,
    imactual,
    vmactual,
    mktworst,
    orgworst,
    accountworst,
    accountimabs,
    accountvmactual,
    orgpml,
    mktpml,
    state,modal,reason,version,created,changed
)
SELECT
    nextval('cf_summary_id_seq'),
    org,
    acc,
    date,
    0,
    max,
    min,
    im,
    vim,
    vma,
    mkt_worst,
    org_worst,
    acc_worst,
    acc_im,
    acc_vma,
    org_pml,
    mkt_pml,
    4,0,0,1,now(),now()
FROM
    temp_cf_sum;

