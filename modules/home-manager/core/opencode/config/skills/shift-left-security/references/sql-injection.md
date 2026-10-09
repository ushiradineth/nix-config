# SQL-injection prevention

## Invariant

Attacker-controlled values must never become SQL text. Keep statement structure trusted and pass
data separately through driver parameters or framework expressions.

Safe `pg` binding:

```ts
await db.query("SELECT * FROM records WHERE id = $1", [request.params.id])
```

Safe Drizzle expression:

```ts
const query = sql`SELECT * FROM records WHERE id = ${request.params.id}`
```

Unsafe construction:

```ts
await db.query(`SELECT * FROM records WHERE id = '${request.params.id}'`)
await db.query("SELECT * FROM records WHERE id = " + request.params.id)
sql.raw(request.query.sort)
```

Treat non-literal `sql.raw(...)` as unsafe unless a narrowly reviewed local rule proves a specific
constant-only case. Reading trusted migration SQL from a checked-in file and constant-only query
construction are distinct from attacker-controlled text; fixtures should preserve those accepted
cases.

Test local rules with paired unsafe and safe examples. Include a concrete payload such as
`' OR 1=1 --`, parameter binding, Drizzle interpolation, trusted migration-file input, and
constant-only construction. Run rule tests before production scans or staged enforcement.
