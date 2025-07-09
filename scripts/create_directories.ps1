# Create project directory structure
$directories = @(
    "sql",
    "sql\ddl",
    "sql\dml", 
    "sql\views",
    "sql\procedures",
    "data",
    "data\sample_data",
    "data\generators",
    "data\schemas",
    "config",
    "config\dev",
    "config\staging", 
    "config\prod",
    "docs",
    "docs\architecture",
    "docs\api",
    "docs\user_guides",
    "tests",
    "tests\unit",
    "tests\integration",
    "tests\e2e",
    "scripts",
    "scripts\deployment",
    "scripts\utilities",
    "scripts\monitoring",
    ".github",
    ".github\workflows",
    "etl\glue_jobs",
    "etl\lambda_functions",
    "etl\step_functions",
    "etl\data_quality",
    "infrastructure\environments\dev",
    "infrastructure\environments\staging",
    "infrastructure\environments\prod"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir
        Write-Host "Created directory: $dir"
    } else {
        Write-Host "Directory already exists: $dir"
    }
}

Write-Host "Directory structure creation completed!"
