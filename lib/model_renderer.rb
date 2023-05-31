# frozen_string_literal: true

class ModelRenderer
  include ZPNG

  attr_reader :model

  def initialize model
    @model = model
    @mask_fname = 'mask4.png'
    @border = false
  end

  def render_all
    r = {}
    case model.render_type
    when :"3d_model", :table_noborder, :table
      Side.each_nsew do |side|
        r[side] = render(side)
      end
    when :flat, :side_south
      r[:flat] = render
    else
      raise "[?] undexpected render type: #{model.render_type}"
    end
    r
  end

  # slow
  def detect_render_type
    images = Side.all.map{ |side| model.render_side(side) }
    usz = images.map(&:export).uniq.size
    if usz == 1 || (usz == 2 && images.any?(&:empty?))
      model.render_type = :flat
    elsif images.any?{ |img| img.pixels.any?(&:transparent?) }
      model.render_type = :"3d_model"
    else
      model.render_type = :table_noborder
    end
  end

  def render side = nil
    detect_render_type if model.render_type.nil?

    type = model.render_type
    side ? send("render_#{type}", side) : send("render_#{type}")
  end

  def render_flat side = nil
    return model.render_side(side).scaled(4) if side

    %w'up north south east west'.each do |side|
      img = model.render_side(Side[side])
      next if img.nil? || img.empty?

      return img.scaled(4)
    end
    nil
  end

#  def render_wall side = Side.north
#    dst = Image.new( width: 64, height: 64 )
#    up_rotated = model.render_top(side)
#    dst.copy_from up_rotated, dst_width: 64, dst_height: 16
#    side_tex = model.render_side(side)
#    dst.copy_from side_tex, dst_width: 64, dst_height: 48, dst_y: 16
#    @mask_fname = 'mask_bottom48.png'
#    mask!(dst, 16)
#    dst
#  end

  def render_side_south
    render_flat Side.south
  end

  def render_table_noborder side = Side.north
    @mask_fname = 'mask4_noborder.png'
    render_table side
  end

  def render_table side = Side.north
    @border = true
    dst = Image.new( width: 64, height: 64 )
    up_rotated = model.render_top(side)
    dst.copy_from up_rotated, dst_width: 64, dst_height: 32
    side_tex = model.render_side(side)
    dst.copy_from side_tex, dst_width: 64, dst_height: 32, dst_y: 32
    mask!(dst)
    land_down_img(dst, side_tex)
  end

  # move _image_ down if it's not full height (stonecutter, enchanting_table, end_portal_frame*)
  def land_down_img img, side_tex
    y = 0
    while side_tex.scanlines[y].pixels.all?(&:transparent?)
      y += 1
    end
    if y != 0
      dst = Image.new( width: 64, height: 64 )
      dst.copy_from img, src_height: 32, dst_y: y*2
      dst.copy_from img, src_y: 32+y*2,  dst_y: 32+y*2
      img = dst
    end
    img
  end

  # move _texture_ down if it's not full height
  def land_down_tex src
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
    @mask_fname = 'mask4_noborder.png'
    dst = Image.new( width: 64, height: 64 )
    up_rotated = land_down_tex(model.render_top(side))
    dst.copy_from up_rotated, dst_width: 32, dst_height: 16, dst_x: 16, dst_y: 16
    side_tex = model.render_side(side)
    dst.copy_from side_tex, dst_width: 32, dst_height: 32, dst_y: 32, dst_x: 16
    mask!(dst)
    land_down_img(dst, side_tex)
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

    if y0 != 0 && @border
      64.times do |x|
        dst[x, 62] = Color::BLACK
        dst[x, 63] = Color::BLACK
      end
    end
  end
end
