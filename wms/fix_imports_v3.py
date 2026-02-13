import os

# Prefix-based mapping for better robustness
REPLACEMENTS = [
    # Specific file moves that don't follow a simple pattern
    ('package:wms/features/warehouse/presentation/pages/employee_notifications_screen.dart', 'package:wms/features/auth/presentation/pages/employee_notifications_screen.dart'),
    ('package:wms/features/warehouse/presentation/pages/employee_profile_screen.dart', 'package:wms/features/auth/presentation/pages/employee_profile_screen.dart'),
    ('package:wms/features/warehouse/presentation/pages/employee_settings_screen.dart', 'package:wms/features/auth/presentation/pages/employee_settings_screen.dart'),
    ('package:wms/features/warehouse/presentation/pages/employee_main_screen.dart', 'package:wms/features/inventory/presentation/pages/employee_main_screen.dart'),
    ('package:wms/features/warehouse/data/sync_service.dart', 'package:wms/core/services/sync_service.dart'),
    ('package:wms/features/warehouse/data/warehouse_layout_data.dart', 'package:wms/core/data/warehouse_layout_data.dart'),
    ('package:wms/core/widgets/supervisorBottonBar.dart', 'package:wms/core/widgets/layout/supervisorBottonBar.dart'),
    ('package:wms/core/widgets/modern_floating_navbar.dart', 'package:wms/core/widgets/layout/modern_floating_navbar.dart'),

    # Supervisor
    ('package:wms/features/warehouse/presentation/cubits/supervisor/', 'package:wms/features/supervisor/presentation/cubits/'),
    ('package:wms/features/warehouse/presentation/pages/supervisor/', 'package:wms/features/supervisor/presentation/pages/'),
    ('package:wms/features/warehouse/data/repositories/ai_review_repository.dart', 'package:wms/features/supervisor/data/repositories/ai_review_repository.dart'),
    ('package:wms/features/warehouse/data/repositories/flag_repository.dart', 'package:wms/features/supervisor/data/repositories/flag_repository.dart'),
    ('package:wms/features/warehouse/data/models/flag_model.dart', 'package:wms/features/supervisor/data/models/flag_model.dart'),
    ('package:wms/features/warehouse/data/models/ai_override_model.dart', 'package:wms/features/supervisor/data/models/ai_override_model.dart'),
    ('package:wms/features/warehouse/data/models/location_point_model.dart', 'package:wms/features/supervisor/data/models/location_point_model.dart'),
    ('package:wms/features/warehouse/presentation/widgets/isometric_warehouse_painter.dart', 'package:wms/features/supervisor/presentation/widgets/isometric_warehouse_painter.dart'),
    ('package:wms/features/warehouse/presentation/pages/flag_resolution_screen.dart', 'package:wms/features/supervisor/presentation/pages/flag_resolution_screen.dart'),
    ('package:wms/features/warehouse/presentation/pages/real_time_map_screen.dart', 'package:wms/features/supervisor/presentation/pages/real_time_map_screen.dart'),
    ('package:wms/features/warehouse/presentation/pages/i_supervisor_approval.dart', 'package:wms/features/supervisor/presentation/pages/i_supervisor_approval.dart'),

    # Inventory
    ('package:wms/features/warehouse/data/repositories/receipt_repository.dart', 'package:wms/features/inventory/data/repositories/receipt_repository.dart'),
    ('package:wms/features/warehouse/data/repositories/transfer_repository.dart', 'package:wms/features/inventory/data/repositories/transfer_repository.dart'),
    ('package:wms/features/warehouse/data/repositories/emplacement_repository.dart', 'package:wms/features/inventory/data/repositories/emplacement_repository.dart'),
    ('package:wms/features/warehouse/data/repositories/entrepot_repository.dart', 'package:wms/features/inventory/data/repositories/entrepot_repository.dart'),
    ('package:wms/features/warehouse/presentation/cubits/employee/receipt_cubit.dart', 'package:wms/features/inventory/presentation/cubits/receipt_cubit.dart'),
    ('package:wms/features/warehouse/presentation/pages/employee/receipt_screen.dart', 'package:wms/features/inventory/presentation/pages/receipt_screen.dart'),
    ('package:wms/features/warehouse/presentation/pages/employee/receipt_details_screen.dart', 'package:wms/features/inventory/presentation/pages/receipt_details_screen.dart'),
    ('package:wms/features/warehouse/presentation/pages/employee/employee_dashboard_screen.dart', 'package:wms/features/inventory/presentation/pages/employee_dashboard_screen.dart'),
    ('package:wms/features/warehouse/data/models/emplacement_model.dart', 'package:wms/features/inventory/data/models/emplacement_model.dart'),
    ('package:wms/features/warehouse/data/models/entrepot_model.dart', 'package:wms/features/inventory/data/models/entrepot_model.dart'),

    # Logistics
    ('package:wms/features/warehouse/data/repositories/picking_repository.dart', 'package:wms/features/logistics/data/repositories/picking_repository.dart'),
    ('package:wms/features/warehouse/data/repositories/delivery_repository.dart', 'package:wms/features/logistics/data/repositories/delivery_repository.dart'),
    ('package:wms/features/warehouse/data/repositories/task_repository.dart', 'package:wms/features/logistics/data/repositories/task_repository.dart'),
    ('package:wms/features/warehouse/data/models/task_model.dart', 'package:wms/features/logistics/data/models/task_model.dart'),
    ('package:wms/features/warehouse/data/models/task_product_model.dart', 'package:wms/features/logistics/data/models/task_product_model.dart'),
    ('package:wms/features/warehouse/presentation/cubits/employee/employee_task_cubit.dart', 'package:wms/features/logistics/presentation/cubits/employee_task_cubit.dart'),
    ('package:wms/features/warehouse/presentation/pages/employee/employee_all_tasks_screen.dart', 'package:wms/features/logistics/presentation/pages/employee_all_tasks_screen.dart'),
    ('package:wms/features/warehouse/presentation/pages/employee/log_task_screen.dart', 'package:wms/features/logistics/presentation/pages/log_task_screen.dart'),
    ('package:wms/features/warehouse/presentation/pages/employee/task_detail_screen.dart', 'package:wms/features/logistics/presentation/pages/task_detail_screen.dart'),
    ('package:wms/features/warehouse/presentation/pages/i_employee_task_view.dart', 'package:wms/features/logistics/presentation/pages/i_employee_task_view.dart'),

    # Auth/Profile (Employee Cubits)
    ('package:wms/features/warehouse/presentation/cubits/employee/employee_notification_cubit.dart', 'package:wms/features/auth/presentation/cubits/employee_notification_cubit.dart'),
    ('package:wms/features/warehouse/presentation/cubits/employee/employee_profile_cubit.dart', 'package:wms/features/auth/presentation/cubits/employee_profile_cubit.dart'),
    ('package:wms/features/warehouse/presentation/cubits/employee/employee_settings_cubit.dart', 'package:wms/features/auth/presentation/cubits/employee_settings_cubit.dart'),

    # Admin
    ('package:wms/features/warehouse/presentation/pages/admin/', 'package:wms/features/admin/presentation/pages/'),
    ('package:wms/features/warehouse/presentation/pages/i_admin_dashboard.dart', 'package:wms/features/admin/presentation/pages/i_admin_dashboard.dart'),

    # Shared Widgets
    ('package:wms/features/warehouse/presentation/widgets/task_views/', 'package:wms/core/widgets/task_views/'),
]

def fix_imports(root_dir):
    print(f"Searching in: {os.path.abspath(root_dir)}")
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    new_content = content
                    for old, new in REPLACEMENTS:
                        new_content = new_content.replace(old, new)
                    
                    if new_content != content:
                        print(f"Updating imports in: {file_path}")
                        with open(file_path, 'w', encoding='utf-8') as f:
                            f.write(new_content)
                except Exception as e:
                    print(f"Error processing {file_path}: {e}")

if __name__ == "__main__":
    # Process both lib and test
    dirs_to_process = ['lib', 'test']
    for d in dirs_to_process:
        if os.path.isdir(d):
            fix_imports(d)
        elif os.path.isdir(f'wms/{d}'):
            fix_imports(f'wms/{d}')
        else:
            print(f"Could not find '{d}' directory!")
