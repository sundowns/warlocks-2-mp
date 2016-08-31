world = {}

function add_entity(name, type, ent)
	world[name] = ent
	world[name].entity_type = type
	--maybe initialise x and y to 0 if they dont exist?
end