-- Tower-Creep Symbiosis Database Schema
-- genome.db: Gene storage, lineage, and execution tracking

CREATE TABLE IF NOT EXISTS genes (
    gene_id TEXT PRIMARY KEY,
    gene_type TEXT NOT NULL,  -- 'behavior' or 'effect'
    display_name TEXT,
    description TEXT,
    gene_data TEXT NOT NULL,  -- JSON blob of gene parameters
    provenance TEXT DEFAULT 'default',  -- 'default', 'synthesized', 'macro-compiled'
    methylation_status INTEGER DEFAULT 0,  -- 0=active, 1=methylated
    error_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,
    last_executed_at INTEGER,
    execution_count INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS gene_lineage (
    lineage_id INTEGER PRIMARY KEY AUTOINCREMENT,
    gene_id TEXT NOT NULL,
    parent_gene_id TEXT,
    mutation_type TEXT,  -- 'seed', 'synthesized', 'macro-compiled', 'evolved'
    mutation_params TEXT,  -- JSON blob of mutation details
    fitness_score REAL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (gene_id) REFERENCES genes(gene_id),
    FOREIGN KEY (parent_gene_id) REFERENCES genes(gene_id)
);

CREATE TABLE IF NOT EXISTS execution_log (
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    gene_id TEXT NOT NULL,
    execution_context TEXT,  -- JSON blob of context at execution time
    result TEXT,  -- JSON blob of execution result
    execution_time_ms REAL,
    success INTEGER,
    timestamp INTEGER NOT NULL,
    FOREIGN KEY (gene_id) REFERENCES genes(gene_id)
);

CREATE INDEX IF NOT EXISTS idx_genes_type ON genes(gene_type);
CREATE INDEX IF NOT EXISTS idx_genes_methylation ON genes(methylation_status);
CREATE INDEX IF NOT EXISTS idx_execution_log_gene ON execution_log(gene_id);
CREATE INDEX IF NOT EXISTS idx_execution_log_timestamp ON execution_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_lineage_gene ON gene_lineage(gene_id);

-- metrics.db: Balance metrics, mutation logs, performance tracking

CREATE TABLE IF NOT EXISTS balance_metrics (
    metric_id INTEGER PRIMARY KEY AUTOINCREMENT,
    composite_balance REAL NOT NULL,
    strategy_diversity REAL,
    player_retention REAL,
    asset_variety REAL,
    creep_health_modifier REAL,
    tower_damage_modifier REAL,
    gold_multiplier REAL,
    spawn_rate_modifier REAL,
    wave_number INTEGER,
    timestamp INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS mutation_log (
    mutation_id INTEGER PRIMARY KEY AUTOINCREMENT,
    mutation_type TEXT NOT NULL,  -- 'nudge', 'rollback', 'macro-compile', 'methylate'
    target_gene_id TEXT,
    parameter_name TEXT,
    old_value REAL,
    new_value REAL,
    json_patch TEXT,  -- Full JSON patch document
    balance_before REAL,
    balance_after REAL,
    timestamp INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS performance_metrics (
    perf_id INTEGER PRIMARY KEY AUTOINCREMENT,
    fps REAL,
    frame_time_ms REAL,
    cpu_utilization REAL,
    memory_pressure REAL,
    active_agents INTEGER,
    work_budget INTEGER,
    tick_duration_ms REAL,
    timestamp INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_balance_timestamp ON balance_metrics(timestamp);
CREATE INDEX IF NOT EXISTS idx_mutation_timestamp ON mutation_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_perf_timestamp ON performance_metrics(timestamp);
