extends Node

@export var cell: PackedScene;

@export var radius: int = 10;
@export var solver_steps: int = 30;
@export var solver: Solver = Solver.JACOBI;
@export var setup: Setup = Setup.CIRCLE;

@onready var rng = RandomNumberGenerator.new();

var running = false;
var steps = 0;

enum Solver {
	JACOBI,
	GAUSS_SEIDEL,
}

enum Setup {
	CIRCLE,
	SQUARE,
}

# Key is a string of form "i,j"
# Value is a Cell
# Actually typing dicts isn't supported in Godot 4.3.stable!
var cells = {};

# Key is a string of form "i,j"
# Value is a float between 0.0 and 1.0
# Actually typing dicts isn't supported in Godot 4.3.stable!
var potentials = {};

# Contains arrays of form [i, j] where i and j are integers
# Actually typing nested arrays isn't supported in Godot 4.3.stable!
var pattern = [];

func _ready() -> void:
	initCells();
		
func simulate() -> void:
	running = true;
	solveField();
	
	while running:
		running = addCell();
		solveField();
		await get_tree().process_frame;

func initCells() -> void:
	cells = {};
	potentials = {};
	pattern = [];
	
	for child in get_children():
		if child is Cell:
			child.queue_free();
	
	# TODO Handle this in a nice way than a horrible switch statement!
	match setup:
		Setup.CIRCLE:
			pass; # TODO implement circle!
		Setup.SQUARE:
			var scale_factor = 9.0 / (radius * 2.0 + 1);
			for i in range(radius * -1, radius + 1):
				for j in range(radius * -1, radius + 1):
					var key = cellKey(i, j);
					var new_cell = cell.instantiate();
					add_child(new_cell);
					new_cell.position = Vector2(i, j) * scale_factor * 64;
					new_cell.scale = Vector2(scale_factor, scale_factor);
					cells[key] = new_cell;
					
					if (i == radius or i == -radius or j == radius or j == -radius):
						new_cell.border = true;
						new_cell.potential = 1.0;
						potentials[key] = 1.0;
					
					elif (i == 0 and j == 0):
						new_cell.added_to_pattern = true;
						new_cell.potential = 0.0;
						new_cell.from = "seed";
						potentials[key] = 0.0;
						pattern.append([0, 0]);
					
					else:
						potentials[key] = 0.5;
						
func solveField() -> void:
	for i in range(solver_steps):
		solveStep();
		
	for i in range(radius * -1, radius + 1):
		for j in range(radius * -1, radius + 1):
			cells[cellKey(i, j)].potential = potentials[cellKey(i, j)];

func solveStep() -> void:
	# TODO Handle this in a nice way than a horrible switch statement!
	match solver:
		Solver.JACOBI:
			var new_potentials = potentials.duplicate()
			for i in range(radius * -1, radius + 1):
				for j in range(radius * -1, radius + 1):
					var key = cellKey(i, j);
					if cells[key].border or cells[key].added_to_pattern:
						continue;
					
					var left_potential = potentials[cellKey(i - 1, j)];
					var right_potential = potentials[cellKey(i + 1, j)];
					var up_potential = potentials[cellKey(i, j - 1)];
					var down_potential = potentials[cellKey(i, j + 1)];
					new_potentials[key] = 1.0/4.0 * (left_potential + right_potential + up_potential + down_potential);
			
			potentials = new_potentials;
		
		Solver.GAUSS_SEIDEL:
			for i in range(radius * -1, radius + 1):
				for j in range(radius * -1, radius + 1):
					var key = cellKey(i, j);
					if cells[key].border or cells[key].added_to_pattern:
						continue;
					
					var left_potential = potentials[cellKey(i - 1, j)];
					var right_potential = potentials[cellKey(i + 1, j)];
					var up_potential = potentials[cellKey(i, j - 1)];
					var down_potential = potentials[cellKey(i, j + 1)];
					potentials[key] = 1.0/4.0 * (left_potential + right_potential + up_potential + down_potential);

func addCell() -> bool:
	# Array of arrays of form [int i, int j, string from_direction]
	var candidates = [];
	
	for patternCell in pattern:		
		var cellNotEqual = func(i, j):
			return func (x):
				return patternCell[0] + i != x[0] or patternCell[1] + j != x[1];

		# TODO Clean this up
		if pattern.all(cellNotEqual.call(-1, 0)):
			candidates.append([patternCell[0] - 1, patternCell[1], "right"]);

		if pattern.all(cellNotEqual.call(1, 0)):
			candidates.append([patternCell[0] + 1, patternCell[1], "left"]);

		if pattern.all(cellNotEqual.call(0, -1)):
			candidates.append([patternCell[0], patternCell[1] - 1, "down"]);

		if pattern.all(cellNotEqual.call(0, 1)):
			candidates.append([patternCell[0], patternCell[1] + 1, "up"]);
	
	var totalPotential = 0.0;
	for candidate in candidates:
		totalPotential += potentials[cellKey(candidate[0], candidate[1])];
	
	var probabilities = [];
	for candidate in candidates:
		if (cells[cellKey(candidate[0], candidate[1])].border):
			return false;
			
		probabilities.append(potentials[cellKey(candidate[0], candidate[1])] / totalPotential);

	var chosenIndex = rng.rand_weighted(probabilities);
	var chosenCell = candidates[chosenIndex];
	steps +=1 ;

	if Global.debug_print:
		print("\n\n")
		print("STEP %s" % steps);
		print("Total potential: %1.2f" % totalPotential)
		print("PROBABILITIES")
		
		if Global.debug_verbose:
			for i in range(candidates.size()):
				print("[%s, %s] Potential: %1.2f Probability: %1.2f%%" %
					[candidates[i][0], candidates[i][1], potentials[cellKey(candidates[i][0], candidates[i][1])], probabilities[i] * 100]);
		
		print("");
		print("CHOSEN")

		print("[%s, %s] Potential: %1.2f Probability: %1.2f%%" %
			[chosenCell[0], chosenCell[1], potentials[cellKey(chosenCell[0], chosenCell[1])], probabilities[chosenIndex] * 100]);

	pattern.append(chosenCell);
	cells[cellKey(chosenCell[0], chosenCell[1])].added_to_pattern = true;
	cells[cellKey(chosenCell[0], chosenCell[1])].potential = 0.0;
	cells[cellKey(chosenCell[0], chosenCell[1])].from = chosenCell[2];
	potentials[cellKey(chosenCell[0], chosenCell[1])] = 0.0;
	
	return true;
	
func cellKey(i: int, j: int) -> String:
	return "%s, %s" % [i, j];


func set_setup(new_value: int) -> void:
	setup = new_value;
	initCells();


func set_radius(new_value: int) -> void:
	radius = new_value;
	initCells();


func set_solver(new_value: int) -> void:
	solver = new_value;

func set_solver_steps(new_value: int) -> void:
	solver_steps = new_value;
