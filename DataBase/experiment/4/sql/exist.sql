SELECT
    A_AND.s,
    A_AND.t,
    (
        CAST(A_AND.com_cnt AS FLOAT) / (deg_s.p_out_cnt + deg_t.p_out_cnt - A_AND.com_cnt)
    ) AS jaccard
FROM
    A_AND
    JOIN DEG deg_s ON A_AND.s = deg_s.p
    JOIN DEG deg_t ON A_AND.t = deg_t.p
WHERE
    EXISTS (
        SELECT
            *
        FROM
            DEG deg_l
            JOIN DEG deg_r ON deg_l.p != deg_r.p
            AND deg_l.p = A_AND.s
            AND deg_r.p = A_AND.t
    )
LIMIT
    3000;

--Error in query: Expressions referencing the outer query are not supported outside of WHERE/HAVING clauses:
-- Join Inner, ((NOT (p#151 = p#153) && (p#151 = outer(s#144))) && (p#153 = outer(t#145)))
-- valid in spark
SELECT
    s,
    t,
    (
        CAST(com_cnt AS FLOAT) / (
            deg_s.p_out_cnt + deg_t.p_out_cnt - com_cnt
        )
    ) AS jaccard
FROM
    (
        SELECT *
        FROM A_AND
        WHERE EXISTS (
            SELECT 1
            FROM DEG deg_l, DEG deg_r
            WHERE deg_l.p != deg_r.p
            AND deg_l.p = A_AND.s
            AND deg_r.p = A_AND.t
        )
    ) filtered
    JOIN DEG deg_s ON filtered.s = deg_s.p
    JOIN DEG deg_t ON filtered.t = deg_t.p
LIMIT 3000;
