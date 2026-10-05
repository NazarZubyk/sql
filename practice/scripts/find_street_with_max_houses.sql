SELECT
	s.name,
	count(h.id) AS houses
FROM
	taxi.street s
JOIN taxi.house h ON
	h.streetID = s.id
GROUP BY
	s.id
ORDER BY
	houses DESC
LIMIT 1