# frozen_string_literal: true

class Model
  class CubeColumnHorizontal < Model
    renders "block/cube_column_horizontal"

    # swap sides
    def initialize *args
      super
      elements.each do |el|
        faces = el['faces']
        faces['up'], faces['north'] = faces['north'], faces['up']
        faces['south'] = faces['north']
        faces['east']['rotation'] = 90
        faces['west']['rotation'] = -90
      end
    end

  end
end
