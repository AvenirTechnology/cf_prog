/*
 * Avenir Technology
 * Clearing Fund SQL Development
 *
 * this file contains the SQL for clearing fund logic (on VSD)
 *
 * Author:  Martyn Bain and simon Smith
 * Date:    11 Dec 2018
 *
 * History: 14 Dec - cf6.sql
 *          add net IM for org based on sign of underlyng acc netpos
 *
 *          11 Dec - cf5.sql
 *          summary table changed to be wide (vs 2 lines per org)
 *          added some additional 'worst' columns
 *
 *          ---  - cf4.sql
 *          initial version
 *
 * ------------------------------------------------------
 *
 */

-- Constants

-- From/to date
\set fr_date 3-jul-2014
\set to_date 30-sept-2018

-- Max/min percentage
\set max 0.12
\set min -0.14

-- Number of cm/accounts to sum
\set pml_acc 2


\set div 100000
\set ON_ERROR_STOP on


/*
 * ------------------------------------------------------
 */

BEGIN;

/*
 * create instrument level table for all dates
 */

CREATE TEMP TABLE tmp_cf_inst (date, acc ,org, inst, del, rec, net, max, min, im, vma)
   ON COMMIT DROP AS
SELECT
    m.date,
    m.account_id,
    m.manager_id,
    m.instrument_id,
    m.Deliver,
    m.Receive,
    m.Net,
    m.mv * :max,
    m.mv * :min,
    m.im,
    m.vm
FROM
    margin_instrument_date m,
    instrument i,
    account a,
    price p
WHERE
    m.instrument_id = i.id
AND m.account_id = a.id
AND m.date >= :'fr_date'
AND m.date <= :'to_date'
AND p.instrument_id = m.instrument_id
AND p.date = m.date;



/*
 * account totals table
 */

CREATE TEMP TABLE tmp_cf_acc (date, org, acc, max, min, worst, im, vim, vma)
   ON COMMIT DROP AS
SELECT
    date,
    org,
    acc,
    sum(max),
    sum(min),
    case when sum(max) > sum(min) then sum(min) else sum(max) end,
    sum(im),
    sum(case when net < 0 then -1 * im else im end),
    sum(vma)
FROM
    tmp_cf_inst
GROUP BY
    date, org, acc;



/*
 * create the aggregated org single/virtual account
 * which is the sum(net) from all managed accounts
 */

CREATE TEMP TABLE tmp_cf_acc1 (date, org, inst, max, min, worst, im, vim, vma)
   ON COMMIT DROP AS
SELECT
    date,
    org,
    inst,
    sum(max),
    sum(min),
    case when sum(max) > sum(min) then sum(min) else sum(max) end,
    sum(im),
    sum(case when net < 0 then -1 * im else im end),
    sum(vma)
FROM
    tmp_cf_inst
GROUP BY
    date, org, inst;


Delete from
    tmp_cf_acc1
WHERE worst = 0
AND   im = 0
AND   vma = 0;


/*
 * create the org summary table (per date)
 * start by populating with the aggregate single/virtual account
 * which is created by tmp_cf_acc1
 */

CREATE TEMP TABLE tmp_cf_sum (date, org, acc, net_worst, max, min, im, vim, vma, mkt_worst, org_worst, acc_worst, acc_im, acc_vma, org_pml, mkt_pml)
   ON COMMIT DROP AS
SELECT
    date,
    org,
    null::integer,
    CASE WHEN sum(max) > sum(min) THEN sum(min) ELSE sum(max) END,
    sum(max),
    sum(min),
    sum(im),
    sum(vim),
    sum(vma),
    0::decimal(30,0),
    0::decimal(30,0),
    0::decimal(30,0),
    0::decimal(30,0),
    0::decimal(30,0),
    0::decimal(30,0),
    0::decimal(30,0)
FROM
    tmp_cf_acc1
GROUP BY
    date, org;


/*
 * update worst account for each CM
 */
UPDATE tmp_cf_sum s
SET    acc = a.acc,
       acc_worst = a.worst,
       acc_im = a.im,
       acc_vma = a.vma
FROM   (
        SELECT DISTINCT ON (date, org) *
        FROM tmp_cf_acc
        ORDER BY date, org, worst
       ) a
WHERE  a.org = s.org
AND    a.date = s.date;


/*
 * global/market worst approach
 * Org worst approach
 * sum of all account worst for each org.
 */

UPDATE  tmp_cf_sum AS t
SET     mkt_worst = (case when s.min < s.max then s.min else s.max end)
FROM    (
        SELECT
            date,
            sum(case when min < 0 then min else 0 end) AS min,
            sum(case when max < 0 then max else 0 end) AS max
        FROM
            tmp_cf_sum
        GROUP BY date
        ) AS s
WHERE
    s.date = t.date;


/*
 * worst accross all CMs for each day
 * as requestd by VSD
 */

UPDATE  tmp_cf_sum t
SET     org_worst = g.worst
FROM    (SELECT     date, MIN(worst) AS worst
        FROM        tmp_cf_acc
        GROUP BY    date
        ) AS g
WHERE   g.date = t.date;


/*
 * calculate PML
 */

UPDATE  tmp_cf_sum
SET     org_pml = abs(org_worst) - im - vma,
        mkt_pml = abs(mkt_worst) - im - vma;



/*
 * PML summary, by date, two cols:
 * 1. sum of worst :pml_acc (number of accounts) for each day
 * 2. plus the maximum one
 */

CREATE TEMP TABLE tmp_cf_pml (date, max_pml, pml)
    ON COMMIT DROP AS
SELECT  date, max(pml), sum(pml)
FROM    (SELECT
            date,pml FROM
                (SELECT
                    date, org, pml, rank() over (PARTITION BY date ORDER BY pml DESC)
                FROM    (SELECT
                            date, org, max(mkt_pml) AS pml
                        FROM
                            tmp_cf_sum
                        GROUP BY date, org
                        ) AS a
                ) AS b
        WHERE
            rank <= :pml_acc
        ) AS c
GROUP BY date;



/*
 * output data to files
 * converting to 'real' numbers with the divisor
 */

\a
\o cf_inst
SELECT date, acc ,org, inst, del, rec, net, round(max/:div) AS max, round(min/:div) AS min, round(im/:div) AS im, round(vma/:div) AS vma FROM tmp_cf_inst;

\o cf_acc
SELECT date, acc ,org, round(max/:div) AS max, round(min/:div) AS min, round(worst/:div) AS worst, round(im/:div) AS im, round(vim/:div) AS vim, round(vma/:div) AS vma FROM tmp_cf_acc;

\o cf_acc1
SELECT date, org, inst, round(max/:div) AS max, round(min/:div) AS min, round(worst/:div) AS worst, round(im/:div) AS im, round(vim/:div) AS vim, round(vma/:div) AS vma FROM tmp_cf_acc1;

\o cf_sum
SELECT date, org, acc,
round(max/:div) AS max, round(min/:div) AS min,
round(mkt_worst/:div) AS mkt_worst,
round(org_worst/:div) AS org_worst,
round(net_worst/:div) AS net_worst, round(im/:div) AS im, round(vim/:div) AS vim, round(vma/:div) AS vma,
round(acc_worst/:div) AS acc_worst, round(acc_im/:div) AS acc_im, round(acc_vma/:div) AS acc_vma,
round(org_pml/:div) AS org_pml, round(mkt_pml/:div) AS mkt_pml
FROM tmp_cf_sum;

\o cf_pml
SELECT date, round(max_pml/:div) AS max_pml, round(pml/:div) AS pml FROM tmp_cf_pml;

END;
