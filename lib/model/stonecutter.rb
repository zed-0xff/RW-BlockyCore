# frozen_string_literal: true

class Model
  class Stonecutter < Model
    renders "block/stonecutter"

    def render_top for_side
      dst = super
      if for_side.north? || for_side.south?
        tex = load_texture(textures['saw'])
        dst.copy_from tex, dst_width: dst.width, dst_height: dst.height, src_height: 16, src_y: 7
      end
      dst
    end

    def render_side *args, **kwargs
      kwargs[:elements] =  elements.filter{ |e| e.dig('faces', 'north', 'texture') != "#saw" }
      super *args, **kwargs
    end
  end
end
