# Redshift Simulation Module

This module sets up a local PostgreSQL container that mimics an Amazon Redshift environment for development and testing purposes.

- Port: `5439`
- DB: `redshift_db`
- User: `redshift_user`
- Password: `redshift_pass`

## Usage

1. Run the container:

```bash
docker-compose up -d
```

2. Connect using any PostgreSQL client (e.g. DBeaver, pgAdmin, psql):

```bash
psql -h localhost -p 5439 -U redshift_user -d redshift_db
```

3. (Optional) Load CSV data manually:

```sql
COPY indicators(province, year, value)
FROM '/sample_data.csv' DELIMITER ',' CSV HEADER;
```