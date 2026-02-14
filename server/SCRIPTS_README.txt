# Server scripts folder

Move here the one-off / debug / seed / migration scripts that are not part of the running app (main.py). This keeps the server root clean for judges and avoids confusion.

Suggested moves (from server/ root):
  check_tasks.py, debug_env.py, test_login_response.py, check_roles.py, check_users.py,
  check_passwords.py, check_auth_users.py, inspect_db.py, inspect_constraints.py, inspect_xlsx.py,
  debug_auth.py, reset_users.py, create_admin.py, create_employee.py, create_supervisor.py,
  elevate_admin.py, update_supervisor_name.py, add_column.py, drop_constraint.py, apply_sql.py,
  apply_missing_schema.py, fix_db.py, check_sync_objects.py, sync_auth_profiles.py, migrate_flags.py,
  seed_flags.py, seed_tasks.py, seed_from_excel.py, seed_data_csv.py, seed_supervisor_data.py,
  create_tasks_table.py

Keep in server/ root: main.py, models.py, schemas.py, database.py, scheduler.py, requirements.txt, and the services/ folder.

Create folder: server/scripts/
Then move the listed .py files into server/scripts/ (or delete if no longer needed).
