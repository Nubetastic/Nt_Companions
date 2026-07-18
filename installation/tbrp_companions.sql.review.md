# Code Review — installation/tbrp_companions.sql

## Summary
Schema is minimal but the PK design conflicts with usage in code.

## High-Impact Fixes
1. Primary key and AUTO_INCREMENT
   - Issue: `charidentifier` is `AUTO_INCREMENT` PK (installation/tbrp_companions.sql:2,7), but server code treats it as the player character id when inserting/updating.
   - Fix: Remove `AUTO_INCREMENT` from `charidentifier`. Use a composite key `(identifier, charidentifier)` as the primary (or add a separate surrogate `id` as AI PK and unique index on `(identifier,charidentifier)`).

## Reliability
- Add indexes:
  - Primary key (or unique) on `(identifier, charidentifier)`
  - Optional index on `identifier` for faster lookups.
- Column sizes:
  - Ensure `identifier` length matches actual citizen id length; 50 may be fine, but confirm with framework.
- Collation/charset:
  - Consider `utf8mb4_unicode_ci` for broader compatibility unless general is required.

## Example (composite PK)
```sql
CREATE TABLE `tbrp_companions` (
  `identifier` VARCHAR(50) NOT NULL,
  `charidentifier` INT(11) NOT NULL,
  `dog` VARCHAR(255) NOT NULL,
  `skin` INT(11) NOT NULL DEFAULT 0,
  `xp` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`, `charidentifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```
