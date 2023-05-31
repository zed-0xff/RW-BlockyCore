# frozen_string_literal: true

class ModelRenderer
  include ZPNG

  attr_reader :model

  def initialize model
    @model = model
  end

  def render side = nil
    type = model.render_type || :flat
    side ? send("render_#{type}", side) : send("render_#{type}")
  end

  def render_flat side = nil
    return model.render_side(side).scaled(4) if side

    %w'up north south east west'.each do |side|
      img = model.render_side(side)
      next if img.nil? || img.pixels.all?(&:transparent?)

      return img.scaled(4)
    end
    nil
  end

  ROT_PER_SIDE = { east: 90, west: 270, north: 180, south: 0 }

  def render_table side = :north
    dst = Image.new( width: 64, height: 64 )
    up_rotated = model.render_side(:up).rotated(ROT_PER_SIDE[side.to_sym])
    dst.copy_from up_rotated, dst_width: 64, dst_height: 32
    if model.textures['saw'] && [:north, :south].include?(side.to_sym)
      # HACK: stonecutter
      tex = model.load_texture(model.textures['saw'])
      dst.copy_from tex, dst_width: 64, dst_height: 32, src_height: 16, src_y: 7
    end
    side_tex = model.render_side(side)
    dst.copy_from side_tex, dst_width: 64, dst_height: 32, dst_y: 32
    mask!(dst)

    # move image down if it's nott full height (stonecutter, enchanting_table)
    y = 15
    while y > 0
      break if !side_tex.scanlines[y].pixels.all?(&:transparent?)
      y -= 1
    end
    if y != 15
      img = Image.new( width: 64, height: 64 )
      img.copy_from(dst, dst_y: (14-y)*2)
      img.copy_from(dst, src_y: 62, dst_y: 62) # border
      dst = img
    end

    dst
  end

  # respect original proportions
  def render_3d_model side = :north
    dst = Image.new( width: 64, height: 64 )
    up_rotated = model.render_side(:up).rotated(ROT_PER_SIDE[side.to_sym])
    dst.copy_from up_rotated, dst_width: 64, dst_height: 32
    dst.copy_from model.render_side(side), dst_width: 64, dst_height: 32, dst_y: 32
    dst
  end

  def mask! dst, y0 = 0
    y0 = 0 if y0 == -1
    @@mask ||= Image.new(File.open(File.join(File.dirname(__FILE__), "mask4.png"),"rb"))
    @@mask.each_pixel do |c,x,y|
      break if y+y0 == 64
      if c.black?
        dst[x,y+y0] = c
      elsif dst[x,y+y0].transparent?
        next
      else
        dst[x,y+y0] *= c
      end
    end

    if y0 != 0
      64.times do |x|
        dst[x, 62] = Color::BLACK
        dst[x, 63] = Color::BLACK
      end
    end
  end
end
