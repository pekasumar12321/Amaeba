extends Node2D

@export var Individuals: Array
@export var MainScene: PackedScene

func createRandom():
	var matrix = []
	for _i in range(16):
		matrix.append(randf() - 0.5)
	return matrix


class Individual extends Object:
	var name := ""
	var genes := []
	var representation: Area2D = null
	var score := -1
	var bestScore := 0
	
	signal gotScore(individual: Individual)

	func _init(genes, name):
		self.genes = genes
		self.name = name

	func getScore(value):
		score = value
		print(score)
		print("got score")
		if value > bestScore:
			bestScore = value
		emit_signal("gotScore", self)


func shallowCopy(ind):
	var clone = Individual.new(ind.genes, ind.name + "I")
	clone.bestScore = ind.bestScore
	return clone

func Ind_got_score(_ind):
	var unscored = Individuals.filter(func(i): return i.score < 0).size()
	if unscored == 0: 
		print("done scoring")
		newGeneration()

var subViews: Array = []

func select(population):
	var selected = []
	var half = population.size() / 2
	for i in range(int(half)):
		selected.append(population[i])
	return selected

func cross(parents):
	var children = parents.duplicate()
	for i in parents:
		var mate = parents[randi_range(0, parents.size() - 1)]
		var child1 := []
		var child2 := []
		for j in range(16):
			if randf() < 0.5:
				child1.append(i.genes[j])
				child2.append(mate.genes[j])
			else:
				child2.append(i.genes[j])
				child1.append(mate.genes[j])
		children.append(Individual.new(child1, str(numberOfIndividuals)))
		numberOfIndividuals += 1
	return children

var numberOfIndividuals := 0

func mutate(population):
	var target = population[randi_range(0, population.size() - 1)]
	var idx = randi_range(0, 15)
	target.genes[idx] = randf() - 0.5
	target.name += "M"
	return population

func newGeneration():
	var copied = Individuals.map(shallowCopy)
	copied.sort_custom(func(a, b): return a.score > b.score)
	var selected = select(copied)
	var crossed = cross(selected)
	var mutated = mutate(crossed)
	reset(mutated)

func reset(population):
	for view in subViews:
		for node in view.get_children():
			view.remove_child(node)
			node.queue_free()
	Individuals.clear()
	for i in range(subViews.size()):
		var ms = MainScene.instantiate()
		var ind = population[i]
		ind.representation = ms
		Individuals.append(ind)
		ind.gotScore.connect(Ind_got_score)
		ms.reflexMatrix = ind.genes
		ms.gameover.connect(ind.getScore)
		ms.NameLabel = ind.name
		ms.BestScore = ind.bestScore
		subViews[i].add_child(ms)

func _ready():
	seed(43)
	var children = $GridContainer.get_children()
	subViews.clear()
	for child in children:
		subViews.append(child.get_child(0))
	var initialPop := []
	for i in range(subViews.size()):
		initialPop.append(Individual.new(createRandom(), str(i)))  # <-- Imena sada bez {}
		numberOfIndividuals += 1
	reset(initialPop)

func _process(_delta):
	pass
