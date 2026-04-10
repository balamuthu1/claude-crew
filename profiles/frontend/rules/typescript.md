# TypeScript Standards

These rules apply to all TypeScript and JavaScript frontend development.

## Strictness

Always use strict TypeScript:
```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "exactOptionalPropertyTypes": true
  }
}
```

## Type definitions

### Never use `any`
```typescript
// Wrong
function processData(data: any) {}

// Correct
function processData(data: UserData) {}
// Or with unknown for truly dynamic data:
function processData(data: unknown) {
  if (isUserData(data)) { ... }
}
```

### Prefer explicit interfaces over inferred types for public APIs
```typescript
// Preferred for API responses and component props
interface UserProfile {
  id: string;
  email: string;
  createdAt: Date;
}

// Inferred is fine for local variables
const users = await fetchUsers(); // type inferred from fetchUsers return type
```

### Discriminated unions for state
```typescript
type AsyncState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };
```

## API types

- Define types for all API request and response shapes
- Never cast API responses with `as` — use type guards or validation (Zod)
- Generate types from OpenAPI spec where possible
- Keep API types in a `types/api.ts` module — not scattered in components

## Component props

```typescript
// Props interface always explicit, named after component
interface UserCardProps {
  user: User;
  onEdit?: (id: string) => void;  // optional with ?
  className?: string;              // allow style extension
}

export function UserCard({ user, onEdit, className }: UserCardProps) {
  ...
}
```

## Error handling

```typescript
// Never swallow errors silently
try {
  await fetchUser(id);
} catch (error) {
  // Always handle: rethrow, log, or display
  if (error instanceof ApiError) {
    setError(error.message);
  } else {
    throw error; // unexpected errors should propagate
  }
}
```

## Type assertions

- Never use `as` to assert types you haven't validated
- Never use `!` (non-null assertion) without a comment explaining why it's safe
- Use type guards instead of assertions:

```typescript
// Wrong
const user = data as User;

// Correct
function isUser(data: unknown): data is User {
  return typeof data === 'object' && data !== null && 'id' in data;
}
if (isUser(data)) { ... }
```

## Imports

- Use named imports over default imports for tree-shaking
- Group imports: external packages → internal modules → relative files
- Avoid barrel re-exports that cause circular dependency issues
