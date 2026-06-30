extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var mesh_body: MeshInstance3D = %MeshBody
@onready var camera_3d: Camera3D = %Camera3D
@onready var nose: MeshInstance3D = %Nose
@onready var nameplate: Label3D = %Nameplate
@onready var head: Node3D = %Head

func _enter_tree() -> void:
	set_multiplayer_authority(int(name))

func _ready() -> void:
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		camera_3d.current = true
		mesh_body.hide()
		nose.hide()
		nameplate.text = str(multiplayer.get_unique_id())
		#nameplate.text = Steam.getPersonaName()

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
var sens = 0.05
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and is_multiplayer_authority():
		rotate_y(-event.relative.x * sens / 10)
		head.rotate_x(-event.relative.y * sens / 10)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
