WITH
    MAPPED AS (
        SELECT
            deg_l.p AS s,
            deg_r.p AS t,
            deg_l.p_out_cnt AS p_out_cnt_s,
            deg_r.p_out_cnt AS p_out_cnt_t
        FROM
            DEG deg_l
            JOIN DEG deg_r ON deg_l.p != deg_r.p
    )
    -- |A U B| = |A| + |B| - |A ^ B|
SELECT
    A_AND.s,
    A_AND.t,
    A_AND.com_cnt AS com_cnt,
    (
        CAST(A_AND.com_cnt AS FLOAT) / (MAPPED.p_out_cnt_s + MAPPED.p_out_cnt_t - com_cnt)
    ) AS jaccard
FROM
    MAPPED
    JOIN A_AND ON MAPPED.s = A_AND.s
    AND MAPPED.t = A_AND.t
LIMIT
    3000;
