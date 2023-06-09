# frozen_string_literal: true

class ModelRenderer
  include ZPNG

  attr_reader :model, :suffix

  def initialize model, suffix
    @model = model
    @mask_fname = 'mask4.png'
    @border = false
    @suffix = suffix
    @render_type = model.render_types&.[](suffix)
    @filters = []
    if @render_type.is_a?(Array)
      @filters = @render_type[1..-1]
      @render_type = @render_type[0]
    end
  end

  def render_all
    r = {}
    case @render_type.to_s
    when /table/, /^log/
      Side.each_nsew do |side|
        r[side] = render(side)
      end
    when 'flat', 'side_south', /3d/, 'cube'
      r[:flat] = render
    else
      raise "[?] unexpected render type: #{@render_type}"
    end
    r
  end

  # slow
  def detect_render_type
    images = Side.all.map{ |side| model.render_side(side) }.compact
    usz = images.map(&:export).uniq.size
    if usz == 1 || (usz == 2 && images.any?(&:empty?))
      @render_type = :flat
    elsif images.any?{ |img| img.pixels.any?(&:transparent?) }
      @render_type = :"3d_model"
    else
      @render_type = :table_noborder
    end
    raise if @model.render_types
    @model.render_types = { '' => @render_type }
    @render_type
  end

  def render side = nil, type = ""
    detect_render_type unless @render_type
    r = side ? send("render_#{@render_type}", side) : send("render_#{@render_type}")
    unless @filtered
      @filters.each do |f|
        r = r.send(f)
      end
    end
    r
  end

  def render_flat side = nil
    return model.render_side(side)&.scaled(4) if side

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
    @filters.each do |f|
      dst = dst.send(f)
    end
    @filtered = true
    mask!(dst)
    land_down_img(dst, side_tex)
  end

  # same as table, but front tex is tiled, not scaled
  def render_log side = Side.north
    @mask_fname = 'mask4_noborder.png'
    @border = false
    dst = Image.new( width: 64, height: 64 )
    up_rotated = land_down_tex(model.render_top(side))
    side_tex = model.render_side(side)
    if side.north? || side.south?
      dst.copy_from up_rotated, dst_width: 32, dst_height: 32, dst_x: 16, dst_y: 0
      dst.copy_from side_tex, dst_width: 32, dst_height: 32, dst_y: 32, dst_x: 16
    else
      dst.copy_from up_rotated, dst_width: 32, dst_height: 16, dst_x: 16, dst_y: 16
      dst.copy_from side_tex, dst_width: 32, dst_height: 16, dst_y: 32, dst_x: 16
    end
    mask!(dst)
    land_down_img(dst, side_tex)
  end

  # front tex is replaced with lower part of top tex, only for east & west sides
  def render_log_horizontal side = Side.north
    return render_table(side) if side.north? || side.south?
    @border = true
    dst = Image.new( width: 64, height: 64 )
    up_rotated = model.render_top(side)
    dst.copy_from up_rotated, dst_width: 64, dst_height: 64
    mask!(dst)
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

  def render_3d_diagonal side = nil, zoom = 1
    dst = Image.new( width: 64, height: 64 )

    up_rotated = land_down_tex(model.render_top(Side.north)).shear(-1,0)
    dst.copy_from up_rotated, dst_x: zoom == 1 ? 16 : 0, dst_y: zoom == 1 ? 16 : 0, dst_width: zoom*32, dst_height: zoom*16

    side_tex = model.render_side(Side.west).shear(0,-1)
    dst.copy_from side_tex, dst_x: 32, dst_y: zoom == 1 ? 15 : -2, dst_width: zoom*16, dst_height: zoom*32

    front_tex = model.render_side(Side.north)
    dst.copy_from front_tex, dst_x: 16-(zoom-1)*16, dst_y: 32, dst_width: 16*zoom, dst_height: 16*zoom

    @mask_fname = 'mask_diagonal.png'
    mask!(dst)
  end

  def render_3d_hd side = nil
    dst = Image.new( width: 64, height: 64 )

    up_rotated = land_down_tex(model.render_top(Side.north)).shear(-1,0)
    dst.copy_from up_rotated, dst_x: 0, dst_y: 16, dst_width: 32, dst_height: 16
    dst.copy_from up_rotated, dst_x: 16, dst_y: 16, dst_width: 32, dst_height: 16

    side_tex = model.render_side(Side.west).shear(0,-1)
    dst.copy_from side_tex, dst_x: 32, dst_y: 16, dst_width: 16, dst_height: 32
    dst.copy_from side_tex, dst_x: 32, dst_y: 32, dst_width: 16, dst_height: 32

    front_tex = model.render_side(Side.north)
    dst.copy_from front_tex, dst_x:  0, dst_y: 32
    dst.copy_from front_tex, dst_x: 16, dst_y: 32
    dst.copy_from front_tex, dst_x:  0, dst_y: 32+16
    dst.copy_from front_tex, dst_x: 16, dst_y: 32+16

    @mask_fname = 'mask_diagonal.png'
    mask!(dst)
  end

  def render_cube side = nil
    dst = Image.new( width: 64, height: 64 )

    up = model.render_top(Side.north)
      .scale(2,1)
#      .add_border
      .shear(-1, 0)

    dst.copy_from up, dst_x: 0, dst_y: 16, dst_width: 48, dst_height: 16

    side_tex = model.render_side(Side.west)
      .scale(1,2)
#      .add_border
      .shear(0, -1)

    dst.copy_from side_tex, dst_x: 32, dst_y: 16, dst_width: 16, dst_height: 48

    front_tex = model.render_side(Side.north)
      .scale(2)
#      .add_border

    dst.copy_from front_tex, dst_x:  0, dst_y: 32, dst_height:32, dst_width: 32

    @mask_fname = 'mask_diagonal.png'
    src = mask!(dst)

    dst = Image.new(width: 64, height: 64)
    dst.copy_from(src, dst_x: 8, dst_y: -8)

#    8.upto(40) do |x|
#      dst[x, 24] = Color::BLACK
#      dst[x, 25] = Color::BLACK
#
#      dst[x, 54] = Color::BLACK
#      dst[x, 55] = Color::BLACK
#
#    end

    dst.inline!
  end

  def mask! dst, y0 = 0
    y0 = 0 if y0 == -1
    @mask ||= Image.new(File.open(File.join(File.dirname(__FILE__), "masks", @mask_fname),"rb"))
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
    dst
  end
end
