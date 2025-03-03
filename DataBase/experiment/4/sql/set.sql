SELECT
    r1.a AS node1,
    r2.a AS node2,
    -- 交集大小 |A ∩ B|
    CAST(
        (
            SELECT
                COUNT(*)
            FROM
                (
                    SELECT DISTINCT
                        b
                    FROM
                        R
                    WHERE
                        a = r1.a
                    INTERSECT
                    SELECT DISTINCT
                        b
                    FROM
                        R
                    WHERE
                        a = r2.a
                )
        ) AS FLOAT
    ) / (
        SELECT
            COUNT(*)
        FROM
            (
                SELECT DISTINCT
                    b
                FROM
                    R
                WHERE
                    a = r1.a
                UNION
                SELECT DISTINCT
                    b
                FROM
                    R
                WHERE
                    a = r2.a
            )
    )
FROM
    R r1
    JOIN R r2 ON r1.a < r2.a
LIMIT
    3000;
