# Database Standards

These rules apply to all database work. Read before writing migrations, queries, or schema changes.

## Schema design

### Naming conventions
- Tables: `snake_case`, plural nouns: `users`, `order_items`
- Columns: `snake_case`: `created_at`, `user_id`
- Primary keys: `id` (UUID preferred over auto-increment for distributed systems)
- Foreign keys: `<referenced_table_singular>_id`: `user_id`, `order_id`
- Index names: `idx_<table>_<column(s)>`: `idx_orders_user_id`
- Unique constraints: `uq_<table>_<column(s)>`: `uq_users_email`

### Column standards
- Always add `created_at` and `updated_at` timestamps
- Use `NOT NULL` by default; nullable columns require justification
- Use `TEXT` over `VARCHAR(n)` unless you need the constraint (PostgreSQL)
- Use `BOOLEAN` not `TINYINT(1)` or `CHAR(1)` for booleans
- Use `TIMESTAMPTZ` (with timezone) not `TIMESTAMP` for UTC-stored datetimes

### Primary keys
- UUID (`gen_random_uuid()`) for public-facing resources (prevents enumeration)
- Serial/sequence for internal high-volume tables (e.g., audit logs)
- Never expose auto-increment IDs in public APIs

## Migration safety rules

### Before writing a migration
1. Will this lock the table? For tables >100k rows, use online migration tools or `CREATE INDEX CONCURRENTLY`
2. Is this reversible? Write a `down` migration
3. Does running application code depend on the column/table still existing?

### Safe migration patterns
```sql
-- SAFE: Add nullable column (no default lock)
ALTER TABLE users ADD COLUMN middle_name TEXT;

-- SAFE: Add index without locking (PostgreSQL)
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);

-- UNSAFE: Adding NOT NULL column without default to large table
-- Instead: 1. Add nullable, 2. Backfill, 3. Add constraint
ALTER TABLE users ADD COLUMN status TEXT;
UPDATE users SET status = 'active';
ALTER TABLE users ALTER COLUMN status SET NOT NULL;
```

### Never do without confirmation
- Drop a table or column
- Truncate a table
- Rename a column or table (breaks running code)
- Change a column type (may require full table rewrite)

## Query standards

### Always
- Parameterised queries only — never string concatenation
- Explicit column list — never `SELECT *` in application code
- `LIMIT` on all list queries
- Use transactions for multi-step writes

### Performance
- `EXPLAIN ANALYZE` for queries on tables >100k rows before deploying
- Index on all foreign key columns (not automatic in PostgreSQL)
- Index on columns used in `WHERE`, `ORDER BY`, `GROUP BY`
- Avoid functions on indexed columns in `WHERE` clauses

### N+1 prevention
- Use eager loading (`JOIN` or `INCLUDE`) for related data
- DataLoader pattern for GraphQL resolvers
- Detect N+1 with query count logging in tests

## Connection management

- Use a connection pool — never open/close connections per request
- Pool size: CPU cores × 2 (starting point, tune with load testing)
- Set connection timeout; handle pool exhaustion gracefully
- Transactions must always commit or rollback — no abandoned transactions
