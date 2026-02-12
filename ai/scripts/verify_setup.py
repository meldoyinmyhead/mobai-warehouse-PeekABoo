"""
Setup Verification Script
Checks if the AI Warehouse Service environment is properly configured
"""

import sys
from pathlib import Path
from typing import List, Tuple

# Color codes for terminal output (Windows compatible)
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'


def check_python_version() -> Tuple[bool, str]:
    """Check Python version >= 3.11"""
    version = sys.version_info
    if version.major >= 3 and version.minor >= 11:
        return True, f"Python {version.major}.{version.minor}.{version.micro}"
    return False, f"Python {version.major}.{version.minor}.{version.micro} (requires 3.11+)"


def check_dependencies() -> Tuple[bool, List[str]]:
    """Check if required packages are installed"""
    required = [
        'pandas', 'numpy', 'scikit-learn', 'xgboost', 
        'fastapi', 'uvicorn', 'pydantic', 'pydantic_settings'
    ]
    
    missing = []
    installed = []
    
    for package in required:
        try:
            __import__(package.replace('-', '_'))
            installed.append(package)
        except ImportError:
            missing.append(package)
    
    return len(missing) == 0, missing


def check_directory_structure() -> Tuple[bool, List[str]]:
    """Check if all required directories exist"""
    # Script is in ai/scripts/, so go up 2 levels to workspace root
    base_path = Path(__file__).parent.parent.parent
    
    required_dirs = [
        'ai/config',
        'ai/core',
        'ai/forecasting/models',
        'ai/optimization',
        'ai/services',
        'ai/api/routes',
        'ai/data/raw',
        'ai/data/processed',
        'ai/data/models',
        'ai/scripts',
        'ai/training',
        'ai/tests'
    ]
    
    missing = []
    for dir_path in required_dirs:
        full_path = base_path / dir_path
        if not full_path.exists():
            missing.append(dir_path)
    
    return len(missing) == 0, missing


def check_data_files() -> Tuple[bool, List[str]]:
    """Check if required data files exist"""
    # Script is in ai/scripts/, so go up 2 levels to workspace root
    base_path = Path(__file__).parent.parent.parent
    data_dir = base_path / 'ai' / 'data' / 'raw'
    
    required_files = [
        'WMS_Hackathon_DataPack_Templates_FR_FV_B7_ONLY.xlsx',
        'products_for_ts_grouped.csv',
        'final.csv'
    ]
    
    missing = []
    found = []
    
    for filename in required_files:
        file_path = data_dir / filename
        if file_path.exists():
            size_mb = file_path.stat().st_size / 1024 / 1024
            found.append(f"{filename} ({size_mb:.1f} MB)")
        else:
            missing.append(filename)
    
    return len(missing) == 0, missing, found


def check_config_files() -> Tuple[bool, List[str]]:
    """Check if configuration files exist"""
    # Script is in ai/scripts/, so go up 2 levels to workspace root
    base_path = Path(__file__).parent.parent.parent
    
    config_files = [
        'requirements.txt',
        '.env.example',
        'ai/config/settings.py',
        'ai/api/app.py'
    ]
    
    missing = []
    for file_path_str in config_files:
        file_path = base_path / file_path_str
        if not file_path.exists():
            missing.append(file_path_str)
    
    return len(missing) == 0, missing


def print_section(title: str):
    """Print a section header"""
    print(f"\n{BLUE}{'=' * 60}{RESET}")
    print(f"{BLUE}{title:^60}{RESET}")
    print(f"{BLUE}{'=' * 60}{RESET}\n")


def print_check(name: str, passed: bool, details: str = ""):
    """Print a check result"""
    status = f"{GREEN}✓ PASS{RESET}" if passed else f"{RED}✗ FAIL{RESET}"
    print(f"{status} | {name}")
    if details:
        print(f"       {details}")


def main():
    """Run all verification checks"""
    print(f"\n{BLUE}{'*' * 60}{RESET}")
    print(f"{BLUE}AI Warehouse Service - Setup Verification{BLUE}{RESET}")
    print(f"{BLUE}{'*' * 60}{RESET}")
    
    all_passed = True
    
    # Check Python version
    print_section("Python Environment")
    passed, message = check_python_version()
    print_check("Python Version", passed, message)
    all_passed &= passed
    
    # Check dependencies
    passed, missing = check_dependencies()
    if passed:
        print_check("Python Packages", True, "All required packages installed")
    else:
        print_check("Python Packages", False, f"Missing: {', '.join(missing)}")
        print(f"       {YELLOW}Fix: pip install {' '.join(missing)}{RESET}")
    all_passed &= passed
    
    # Check directory structure
    print_section("Directory Structure")
    passed, missing = check_directory_structure()
    if passed:
        print_check("Required Directories", True, "All directories present")
    else:
        print_check("Required Directories", False, f"Missing: {len(missing)} directories")
        for dir_name in missing[:5]:  # Show first 5
            print(f"       - {dir_name}")
    all_passed &= passed
    
    # Check configuration files
    passed, missing = check_config_files()
    if passed:
        print_check("Configuration Files", True, "All config files present")
    else:
        print_check("Configuration Files", False, f"Missing: {', '.join(missing)}")
    all_passed &= passed
    
    # Check data files
    print_section("Data Files")
    passed, missing, found = check_data_files()
    if passed:
        print_check("Required Data Files", True, "All data files present")
        for file_info in found:
            print(f"       ✓ {file_info}")
    else:
        print_check("Required Data Files", False, f"Missing: {', '.join(missing)}")
    all_passed &= passed
    
    # Final summary
    print_section("Summary")
    if all_passed:
        print(f"{GREEN}{'✓' * 60}{RESET}")
        print(f"{GREEN}All checks passed! Your environment is ready.{RESET}")
        print(f"{GREEN}{'✓' * 60}{RESET}")
        print(f"\n{YELLOW}Next steps:{RESET}")
        print(f"  1. Run: python -m ai.scripts.load_sample_data")
        print(f"  2. Run: python -m ai.scripts.preprocess_data")
        print(f"  3. Run: uvicorn ai.api.app:app --reload")
        print(f"  4. Visit: http://localhost:8000/api/v1/docs")
    else:
        print(f"{RED}{'✗' * 60}{RESET}")
        print(f"{RED}Some checks failed. Please fix the issues above.{RESET}")
        print(f"{RED}{'✗' * 60}{RESET}")
        print(f"\n{YELLOW}Get help:{RESET}")
        print(f"  - Check QUICKSTART.md for setup instructions")
        print(f"  - Check README.md for detailed documentation")
    
    print(f"\n{BLUE}{'*' * 60}{RESET}\n")
    
    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())
