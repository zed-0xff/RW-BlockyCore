# frozen_string_literal: true

class Model
  class EnchantingTable < Model
    renders "block/enchanting_table"

    # make it full-height
    def render_side side, **kwargs
      src = super side, **kwargs
      return src if side.up?

      dst = load_texture("block/obsidian").dup
      y = 0
      y+=1 while src.scanlines[y].pixels.all?(&:transparent?)
      dst.copy_from src, src_y: y, src_height: 5
      dst
    end
  end
end
