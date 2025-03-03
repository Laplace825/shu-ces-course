SELECT
    A_AND.s,
    A_AND.t,
    (
        CAST(A_AND.com_cnt AS FLOAT) / (
            (
                SELECT
                    MAX(p_out_cnt)
                FROM
                    DEG
                WHERE
                    p = A_AND.s
            ) + (
                SELECT
                    MAX(p_out_cnt)
                FROM
                    DEG
                WHERE
                    p = A_AND.t
            ) - A_AND.com_cnt
        )
    ) AS jaccard
FROM
    A_AND
LIMIT
    3000;
