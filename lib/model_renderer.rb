# frozen_string_literal: true

class ModelRenderer
  include ZPNG

  attr_reader :model

  def initialize model
    @model = model
    @mask_fname = 'mask4.png'
  end

  def render side = nil
    type = model.render_type || :flat
    side ? send("render_#{type}", side) : send("render_#{type}")
  end

  def render_flat side = nil
    return model.render_side(side).scaled(4) if side

    %w'up north south east west'.each do |side|
      img = model.render_side(Side[side])
      next if img.nil? || img.pixels.all?(&:transparent?)

      return img.scaled(4)
    end
    nil
  end

  def render_table_noborder side = Side.north
    @mask_fname = 'mask4_noborder.png'
    render_table side
  end

  def render_table side = Side.north
    dst = Image.new( width: 64, height: 64 )
    up_rotated = model.render_top(side)
    dst.copy_from up_rotated, dst_width: 64, dst_height: 32
    side_tex = model.render_side(side)
    dst.copy_from side_tex, dst_width: 64, dst_height: 32, dst_y: 32

    y = 0
    while side_tex.scanlines[y].pixels.all?(&:transparent?)
      y += 1
    end

    mask!(dst)

    # move image down if it's not full height (stonecutter, enchanting_table, end_portal_frame*)
    if y != 0
      img = Image.new( width: 64, height: 64 )
      img.copy_from(dst, src_height: 32, dst_y: y)
      img.copy_from(dst, src_y: 32+y, dst_y: 32)
      dst = img
    end

    dst
  end

  # move _texture_ down if it's not full height
  def land_down src
    y = src.height - 1
    while y > 0
      break if !src.scanlines[y].pixels.all?(&:transparent?)
      y -= 1
    end
    if y != src.height - 1
      dst = Image.new( width: src.width, height: src.height, bpp: src.bpp )
      dst.copy_from(src, dst_y: (src.height - 1 - y))
      src = dst
    end
    src
  end

  # respect original proportions
  def render_3d_model side = Side.north
    dst = Image.new( width: 64, height: 64 )
    up_rotated = land_down(model.render_top(side))
    dst.copy_from up_rotated, dst_width: 32, dst_height: 16, dst_x: 16, dst_y: 16
    dst.copy_from model.render_side(side), dst_width: 32, dst_height: 32, dst_y: 32, dst_x: 16
    dst
  end

  def mask! dst, y0 = 0
    y0 = 0 if y0 == -1
    @mask ||= Image.new(File.open(File.join(File.dirname(__FILE__), @mask_fname),"rb"))
    @mask.each_pixel do |c,x,y|
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
