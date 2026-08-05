extends Node
## GenomeRegistry - Gene management and execution system
##
## Manages gene registration, execution, and methylation.
## Provides gene pool management for the evolution engine.

signal gene_registered(gene_id: String)
signal gene_methylated(gene_id: String)
signal gene_pruned(gene_id: String)
signal error_threshold_exceeded(gene_id: String)

# In-memory gene storage
var _loaded_genes: Dictionary = {}
var _gene_errors: Dictionary = {}

# Configuration
const MAX_METHYLATION_ERRORS: int = 20
const PRUNE_THRESHOLD_CYCLES: int = 50

var _cycles_since_last_prune: int = 0

func _ready() -> void:
	print("[GenomeRegistry] Initialized - %d genes loaded" % _loaded_genes.size())

## Register a new gene
func register_gene(gene_id: String, gene_resource: Resource) -> bool:
	if _loaded_genes.has(gene_id):
		print("[GenomeRegistry] Gene %s already registered" % gene_id)
		return false
	
	_loaded_genes[gene_id] = gene_resource
	_gene_errors[gene_id] = 0
	gene_registered.emit(gene_id)
	print("[GenomeRegistry] Registered gene: %s" % gene_id)
	return true

## Execute a gene and return behavior context
func execute_gene(gene_id: String, context: Dictionary) -> Dictionary:
	if not _loaded_genes.has(gene_id):
		push_warning("[GenomeRegistry] Gene not found: %s" % gene_id)
		return {"move_direction": Vector2(0, 0), "error": "gene_not_found"}
	
	var gene = _loaded_genes[gene_id]
	if gene.has_method("_evaluate"):
		var result = gene._evaluate(context)
		return result
	
	return {"move_direction": Vector2(0, 0), "error": "no_evaluate_method"}

## Record an error for a gene
func record_error(gene_id: String) -> void:
	if not _gene_errors.has(gene_id):
		_gene_errors[gene_id] = 0
	
	_gene_errors[gene_id] += 1
	
	if _gene_errors[gene_id] >= MAX_METHYLATION_ERRORS:
		methylate_gene(gene_id)

## Methylate (deactivate) a gene due to errors
func methylate_gene(gene_id: String) -> void:
	if _loaded_genes.has(gene_id):
		_loaded_genes.erase(gene_id)
		gene_methylated.emit(gene_id)
		print("[GenomeRegistry] Methylated gene: %s (errors: %d)" % [gene_id, _gene_errors[gene_id]])
	
	if _gene_errors.has(gene_id):
		_gene_errors.erase(gene_id)

## Prune old genes to manage memory
func prune_gene(gene_id: String) -> void:
	if _loaded_genes.has(gene_id):
		_loaded_genes.erase(gene_id)
		gene_pruned.emit(gene_id)
		print("[GenomeRegistry] Pruned gene: %s" % gene_id)

## Check if gene is loaded
func has_gene(gene_id: String) -> bool:
	return _loaded_genes.has(gene_id)

## Get loaded gene count
func get_active_gene_count() -> int:
	return _loaded_genes.size()

## Get gene error rate for balancing
func get_gene_error_rates() -> Dictionary:
	return _gene_errors.duplicate()

## Get strategy diversity metric
func get_strategy_diversity() -> float:
	if _loaded_genes.size() < 2:
		return 0.0
	return clampf(float(_loaded_genes.size()) / 20.0, 0.0, 1.0)