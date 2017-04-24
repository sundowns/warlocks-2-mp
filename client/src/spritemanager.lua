sprite_bank = {}
image_bank = {}

local manager_version = "0.0.1"

function load_sprite(sprite_def)
  local err, sprite_file
  sprite_file, err = love.filesystem.load(sprite_def)
  if not sprite_file then
    print('[ERROR] The following error happend: ' .. tostring(err))
    return nil
  end

  local old_sprite = sprite_bank[sprite_def]
  sprite_bank[sprite_def] = sprite_file()

  if sprite_bank[sprite_def].serialization_version ~= manager_version then
        print("Attempt to load file with incompatible versions: "..sprite_def)
        print("Expected version "..manager_version..", got version "
                ..sprite_bank[sprite_def].serialization_version.." .")
        sprite_bank[sprite_def] = old_sprite --
        return sprite_bank[sprite_def]
    end

    local sprite_sheet = sprite_bank[sprite_def].image

    local old_image = image_bank[sprite_sheet]
    image_bank[sprite_sheet] = love.graphics.newImage(sprite_sheet)

    if image_bank[sprite_sheet] == nil then
        image_bank [sprite_sheet] = old_image   -- Revert image
        sprite_bank[sprite_def] = old_sprite    -- Revert sprite

        print("Failed loading sprite "..sprite_def..", invalid image path ( "
                ..sprite_sheet.." ).")
    end

    return sprite_bank[sprite_def]
end

function get_sprite_instance(sprite_def, size_scale)
      if sprite_def == nil then return nil end

      if sprite_bank[sprite_def] == nil then
          if load_sprite(sprite_def) == nil then return nil end
      end
      return {
          sprite = sprite_bank[sprite_def],
          curr_anim = sprite_bank[sprite_def].animations_names[1],
          curr_frame = 1,
          elapsed_time = 0,
          size_scale = size_scale or 1,
          time_scale = 1, --slow-mo?
          rotation = 0
      }
end

function update_sprite_instance(instance, dt, rotation)
    if rotation then instance.rotation = rotation end
    instance.elapsed_time = instance.elapsed_time + dt
    if instance.elapsed_time > instance.sprite.frame_duration * instance.time_scale then
        if instance.curr_frame < #instance.sprite.animations[instance.curr_anim] then
            instance.curr_frame = instance.curr_frame + 1
        else
            instance.curr_frame = 1
        end
        instance.elapsed_time = 0
    end
end

function draw_instance (instance, x, y, flip_x, flip_y)
    local x_scale = instance.size_scale
    local y_scale = instance.size_scale

    if flip_x then x_scale = -1*x_scale end
    if flip_y then y_scale = -1*y_scale end

    love.graphics.draw (
        image_bank[instance.sprite.image],
        instance.sprite.animations[instance.curr_anim][instance.curr_frame],
        x,
        y,
        instance.rotation,
        x_scale,
        y_scale
    )
end
