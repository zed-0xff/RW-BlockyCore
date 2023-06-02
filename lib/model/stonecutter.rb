# frozen_string_literal: true

class Model
  class Stonecutter < Model
    renders "block/stonecutter"

    # add saw
    def render_top for_side
      dst = super
      if for_side.north? || for_side.south?
        tex = load_texture(textures['saw'])
        dst.copy_from tex, dst_width: dst.width, dst_height: dst.height, src_height: 16, src_y: 7
      end
      dst
    end

    # remove saw
    # make it full-height
    def render_side side, **kwargs
      kwargs[:elements] = elements.filter{ |e| e.dig('faces', 'north', 'texture') != "#saw" }
      src = super side, **kwargs
      return src if side.up?

      dst = Image.new width: 16, height: 16, bpp: src.bpp
      dst.copy_from src, src_y: 7, src_height: (16-7), dst_height: 16
      dst
    end
  end
end
