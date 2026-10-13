# PostgreSQL Logical Replication Project

This project demonstrates PostgreSQL Logical Replication between two databases running on the same PostgreSQL server.

The publisher database is 'company'.

The subscriber database is `dup_company`.

The `customers` table is created as an empty table in both databases. Data is inserted only after the replication setup is fully completed and verified.

## Project Flow

```text
1. Configure PostgreSQL server
2. Create publisher database: company
3. Create subscriber database: dup_company
4. Create empty customers table in company
5. Create publication
6. Create logical replication slot
7. Create empty customers table in dup_company
8. Create subscription
9. Verify replication status
10. Insert test data in company
11. Verify data in dup_company
12. Bulk import 1,000 customer records
13. Verify bulk data replication
```

## Architecture

```text
PostgreSQL Server (localhost:5432)
│
├── postgres
│   └── Common administrative database
│
├── company
│   └── public.customers
│       └── Publisher table
│
└── dup_company
    └── public.customers
        └── Subscriber table
```

## Why Data Is Inserted Last

In this project, no data is inserted into the publisher table during the initial setup.

This approach proves that logical replication is working in real time:

```text
Empty publisher table  -->  Empty subscriber table
            |
            | Insert new record
            v
Publisher receives INSERT
            |
            v
Subscriber automatically receives same INSERT
```

The subscription is created with:

```sql
copy_data = true
```

Because the publisher table is empty at setup time, there is no initial data to copy. After replication becomes active, every new INSERT, UPDATE, DELETE, and TRUNCATE is replicated.

## Server Configuration

Run these commands in the common `postgres` database:

```sql
ALTER SYSTEM SET wal_level = 'logical';
ALTER SYSTEM SET max_wal_senders = 10;
ALTER SYSTEM SET max_replication_slots = 10;
```

### wal_level = logical

PostgreSQL stores database changes in WAL (Write-Ahead Log).

The default value is `replica`, which records enough information for crash recovery and physical replication.

Setting it to `logical` records additional row-level details required for logical replication:

- Which table changed
- Which row changed
- New values after INSERT or UPDATE
- Which row was deleted

### max_wal_senders = 10

This allows up to 10 WAL sender processes.

A WAL sender sends changes from the publisher to the subscriber.

```text
Publisher
   |
   |-- WAL sender --> Subscriber
```

### max_replication_slots = 10

This allows up to 10 replication slots.

A replication slot is a bookmark that remembers which changes the subscriber has already received.

Example:

```text
Publisher WAL:
1. INSERT customer 1
2. INSERT customer 2
3. UPDATE customer 1

Replication slot:
"Subscriber has received changes 1 and 2"
```

If the subscriber disconnects, PostgreSQL keeps pending changes and sends them when it reconnects.

## Important: Same Server Setup

Because both databases are on the same PostgreSQL server, the replication slot is created manually in the publisher database.

The subscription is created using:

```sql
create_slot = false
```

This prevents the `CREATE SUBSCRIPTION` command from hanging.

## Setup Instructions

### Step 1: Configure PostgreSQL server

Connect to the `postgres` database:

```sql
ALTER SYSTEM SET wal_level = 'logical';
ALTER SYSTEM SET max_wal_senders = 10;
ALTER SYSTEM SET max_replication_slots = 10;
```

Restart PostgreSQL.

Verify:

```sql
SHOW wal_level;
SHOW max_wal_senders;
SHOW max_replication_slots;
```

Expected output:

```text
 logical
 10
 10
```

### Step 2: Create databases

Connect to `postgres`:

```sql
CREATE DATABASE company;
CREATE DATABASE dup_company;
```

### Step 3: Create replication user

Connect to `postgres`:

```sql
CREATE ROLE replicator
WITH LOGIN REPLICATION PASSWORD 'YOUR_REPLICATION_PASSWORD';

GRANT CONNECT ON DATABASE company TO replicator;
```

### Step 4: Create empty publisher table

Connect to `company`:

```sql
CREATE TABLE public.customers
(
    customer_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    city          VARCHAR(100),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

GRANT USAGE ON SCHEMA public TO replicator;
GRANT SELECT ON TABLE public.customers TO replicator;
```

Verify the table is empty:

```sql
SELECT COUNT(*) FROM public.customers;
```

Expected:

```text
0
```

### Step 5: Create publication

Connect to `company`:

```sql
CREATE PUBLICATION sales_publication
FOR TABLE public.customers
WITH (publish = 'insert, update, delete, truncate');
```

### Step 6: Create replication slot

Connect to `company`:

```sql
SELECT pg_create_logical_replication_slot(
    'sales_subscription',
    'pgoutput'
);
```

### Step 7: Create empty subscriber table

Connect to `dup_company`:

```sql
CREATE TABLE public.customers
(
    customer_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    city          VARCHAR(100),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

Verify:

```sql
SELECT COUNT(*) FROM public.customers;
```

Expected:

```text
0
```

### Step 8: Create subscription

Connect to `dup_company`:

```sql
CREATE SUBSCRIPTION sales_subscription
CONNECTION
'host=127.0.0.1 port=5432 dbname=company user=replicator password=YOUR_REPLICATION_PASSWORD'
PUBLICATION sales_publication
WITH
(
    slot_name = 'sales_subscription',
    copy_data = true,
    create_slot = false,
    enabled = true
);
```

## Verify Replication Before Inserting Data

Run in `company`:

```sql
SELECT *
FROM pg_stat_replication;

SELECT *
FROM pg_replication_slots;
```

Run in `dup_company`:

```sql
SELECT *
FROM pg_stat_subscription;

SELECT
    srrelid::regclass AS table_name,
    srsubstate
FROM pg_subscription_rel;
```

Expected table state:

```text
   table_name    | srsubstate
-----------------+------------
 customers | r
```

`r` means the table is ready for normal replication.

## Bulk Import After Replication

After confirming that single-row replication works, 1,000 customer records were imported into the publisher table `public.customers` using **pgAdmin’s Import/Export Data** tool.

### Import Steps

1. Open pgAdmin
2. Connect to the `company` database
3. Navigate to:

```text
Databases → company → Schemas → public → Tables → customers
```

4. Right-click the `customers` table
5. Select **Import/Export Data…**
6. Move the option to **Import**
7. Select the CSV file:

```text
customers_1000.csv
```

8. Configure the import options:
   - Format: `csv`
   - Encoding: `UTF8`
   - Header: `Yes`
   - Delimiter: `,`
9. Click **OK**

### CSV Format

The CSV file contains the following columns:

```csv
customer_name,email,city
Vignesh Kumar,vignesh@example.com,Chennai
Anita Rao,anita@example.com,Bengaluru
```

The `customer_id` column is not included in the CSV because it is automatically generated by PostgreSQL using:

```sql
BIGINT GENERATED ALWAYS AS IDENTITY
```

### Verify Bulk Import

Run in `company`:

```sql
SELECT COUNT(*) AS publisher_row_count
FROM public.customers;
```

Expected:

```text
1000
```

Then verify that all 1,000 rows were replicated to the subscriber database:

```sql
-- Run in company_replica
SELECT COUNT(*) AS subscriber_row_count
FROM public.customers;
```

Expected:

```text
1000

## Final Step: Insert Test Data

Only after replication is verified, insert data in `company`:

```sql
INSERT INTO public.customers
(
    customer_name,
    email,
    city
)
VALUES
(
    'Vignesh Kumar',
    'vignesh@example.com',
    'Chennai'
);
```

Then check `dup_company`:

```sql
SELECT *
FROM public.customers;
```

The same row should appear automatically.

## Technologies Used

- PostgreSQL
- SQL
- Logical Replication
- WAL
- Publications and Subscriptions
- Replication Slots
- pgAdmin
- psql
- pg_dump
- pg_restore
- CSV bulk import
- Git
- GitHub
