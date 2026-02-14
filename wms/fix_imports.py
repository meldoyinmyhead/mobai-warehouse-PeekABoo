import os

# Mapping of old import chunks to new import chunks
MAPPING = {
    # Models
    'package:wms/features/warehouse/data/models/flag_model.dart': 'package:wms/features/supervisor/data/models/flag_model.dart',
    'package:wms/features/warehouse/data/models/ai_override_model.dart': 'package:wms/features/supervisor/data/models/ai_override_model.dart',
    'package:wms/features/warehouse/data/models/emplacement_model.dart': 'package:wms/features/inventory/data/models/emplacement_model.dart',
    'package:wms/features/warehouse/data/models/entrepot_model.dart': 'package:wms/features/inventory/data/models/entrepot_model.dart',
    'package:wms/features/warehouse/data/models/task_model.dart': 'package:wms/features/logistics/data/models/task_model.dart',
    'package:wms/features/warehouse/data/models/task_product_model.dart': 'package:wms/features/logistics/data/models/task_product_model.dart',
    'package:wms/features/warehouse/data/models/location_point_model.dart': 'package:wms/features/supervisor/data/models/location_point_model.dart',
    
    # Repositories
    'package:wms/features/warehouse/data/repositories/flag_repository.dart': 'package:wms/features/supervisor/data/repositories/flag_repository.dart',
    'package:wms/features/warehouse/data/repositories/ai_review_repository.dart': 'package:wms/features/supervisor/data/repositories/ai_review_repository.dart',
    'package:wms/features/warehouse/data/repositories/receipt_repository.dart': 'package:wms/features/inventory/data/repositories/receipt_repository.dart',
    'package:wms/features/warehouse/data/repositories/transfer_repository.dart': 'package:wms/features/inventory/data/repositories/transfer_repository.dart',
    'package:wms/features/warehouse/data/repositories/emplacement_repository.dart': 'package:wms/features/inventory/data/repositories/emplacement_repository.dart',
    'package:wms/features/warehouse/data/repositories/entrepot_repository.dart': 'package:wms/features/inventory/data/repositories/entrepot_repository.dart',
    'package:wms/features/warehouse/data/repositories/picking_repository.dart': 'package:wms/features/logistics/data/repositories/picking_repository.dart',
    'package:wms/features/warehouse/data/repositories/delivery_repository.dart': 'package:wms/features/logistics/data/repositories/delivery_repository.dart',
    'package:wms/features/warehouse/data/repositories/task_repository.dart': 'package:wms/features/logistics/data/repositories/task_repository.dart',
    
    # Cubits (Supervisor)
    'package:wms/features/warehouse/presentation/cubits/supervisor/ai_review_cubit.dart': 'package:wms/features/supervisor/presentation/cubits/ai_review_cubit.dart',
    'package:wms/features/warehouse/presentation/cubits/supervisor/flag_cubit.dart': 'package:wms/features/supervisor/presentation/cubits/flag_cubit.dart',
    'package:wms/features/warehouse/presentation/cubits/supervisor/map_cubit.dart': 'package:wms/features/supervisor/presentation/cubits/map_cubit.dart',
    
    # Cubits (Employee -> Inventory/Logistics/Auth)
    'package:wms/features/warehouse/presentation/cubits/employee/receipt_cubit.dart': 'package:wms/features/inventory/presentation/cubits/receipt_cubit.dart',
    'package:wms/features/warehouse/presentation/cubits/employee/employee_task_cubit.dart': 'package:wms/features/logistics/presentation/cubits/employee_task_cubit.dart',
    'package:wms/features/warehouse/presentation/cubits/employee/employee_notification_cubit.dart': 'package:wms/features/auth/presentation/cubits/employee_notification_cubit.dart',
    'package:wms/features/warehouse/presentation/cubits/employee/employee_profile_cubit.dart': 'package:wms/features/auth/presentation/cubits/employee_profile_cubit.dart',
    'package:wms/features/warehouse/presentation/cubits/employee/employee_settings_cubit.dart': 'package:wms/features/auth/presentation/cubits/employee_settings_cubit.dart',
    
    # Pages (Supervisor)
    'package:wms/features/warehouse/presentation/pages/supervisor/supervisor_dashboard_screen.dart': 'package:wms/features/supervisor/presentation/pages/supervisor_dashboard_screen.dart',
    'package:wms/features/warehouse/presentation/pages/supervisor/ai_review_screen.dart': 'package:wms/features/supervisor/presentation/pages/ai_review_screen.dart',
    'package:wms/features/warehouse/presentation/pages/supervisor/flag_management_screen.dart': 'package:wms/features/supervisor/presentation/pages/flag_management_screen.dart',
    'package:wms/features/warehouse/presentation/pages/supervisor/warehouse_map_screen.dart': 'package:wms/features/supervisor/presentation/pages/warehouse_map_screen.dart',
    'package:wms/features/warehouse/presentation/pages/supervisor/supervisor_settings_screen.dart': 'package:wms/features/supervisor/presentation/pages/supervisor_settings_screen.dart',
    
    # Pages (Admin)
    'package:wms/features/warehouse/presentation/pages/admin/access_logs.dart': 'package:wms/features/admin/presentation/pages/access_logs.dart',
    'package:wms/features/warehouse/presentation/pages/admin/admin_dashboard_screen.dart': 'package:wms/features/admin/presentation/pages/admin_dashboard_screen.dart',
    'package:wms/features/warehouse/presentation/pages/admin/ai_performance_screen.dart': 'package:wms/features/admin/presentation/pages/ai_performance_screen.dart',
    'package:wms/features/warehouse/presentation/pages/admin/export.dart': 'package:wms/features/admin/presentation/pages/export.dart',
    'package:wms/features/warehouse/presentation/pages/admin/export_reports_screen.dart': 'package:wms/features/admin/presentation/pages/export_reports_screen.dart',
    
    # Pages (Employee -> Inventory/Logistics) - Note: Using folder-wide match if possible, but explicit is safer
    'package:wms/features/warehouse/presentation/pages/employee/receipt_screen.dart': 'package:wms/features/inventory/presentation/pages/receipt_screen.dart',
    'package:wms/features/warehouse/presentation/pages/employee/receipt_details_screen.dart': 'package:wms/features/inventory/presentation/pages/receipt_details_screen.dart',
    'package:wms/features/warehouse/presentation/pages/employee/employee_dashboard_screen.dart': 'package:wms/features/inventory/presentation/pages/employee_dashboard_screen.dart',
    'package:wms/features/warehouse/presentation/pages/employee/employee_all_tasks_screen.dart': 'package:wms/features/logistics/presentation/pages/employee_all_tasks_screen.dart',
    'package:wms/features/warehouse/presentation/pages/employee/log_task_screen.dart': 'package:wms/features/logistics/presentation/pages/log_task_screen.dart',
    'package:wms/features/warehouse/presentation/pages/employee/task_detail_screen.dart': 'package:wms/features/logistics/presentation/pages/task_detail_screen.dart',

    # Widgets
    'package:wms/features/warehouse/presentation/widgets/isometric_warehouse_painter.dart': 'package:wms/features/supervisor/presentation/widgets/isometric_warehouse_painter.dart',
    'package:wms/core/widgets/supervisorBottonBar.dart': 'package:wms/core/widgets/layout/supervisorBottonBar.dart',
    'package:wms/core/widgets/modern_floating_navbar.dart': 'package:wms/core/widgets/layout/modern_floating_navbar.dart',
    
    # Widgets Folder (Task views)
    'package:wms/features/warehouse/presentation/widgets/task_views/': 'package:wms/core/widgets/task_views/',
}

def fix_imports(root_dir):
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = content
                for old, new in MAPPING.items():
                    new_content = new_content.replace(old, new)
                
                if new_content != content:
                    print(f"Updating imports in: {file_path}")
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(new_content)

if __name__ == "__main__":
    fix_imports('wms/lib')
