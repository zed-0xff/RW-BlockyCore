# frozen_string_literal: true
require 'active_support/core_ext/string'
require 'awesome_print'
require 'fileutils'
require 'zpng'

include ZPNG

class TextureConverter
  def convert! top:, front: nil, side: nil, dst_fname:, flat: false, rotate_top: nil, rotate_front: nil, scale_x: nil, scale_y: nil
    rotate_top = normalize_rotate(rotate_top)
    rotate_front = normalize_rotate(rotate_front)
    scale_x ||= SCALE_X
    scale_y ||= SCALE_Y

    dst = ZPNG::Image.new :width => 64, :height => 64

    if @extra_tex
      if (tex=@extra_tex.delete(:inside))
        _scale(dst, tex, 63, scale_x: scale_x, scale_y: 4)
      end
      @extra_tex.values.each do |fname|
        _scale(dst, fname, 63, scale_x: scale_x, scale_y: 4)
      end
    end

    if flat
      _scale(dst, top, 63, scale_x: scale_x, scale_y: scale_x) # equal scale
    else
      y1 = _scale(dst, front||side, 63, rotate: rotate_front, scale_x: scale_x, scale_y: scale_y)
      return unless y1

      y2 = _scale(dst, top, y1, rotate: rotate_top, scale_x: scale_x, scale_y: scale_y)

      if scale_x == 2
        y1 = _scale(dst, front||side, 63, rotate: rotate_front, scale_x: scale_x, scale_y: scale_y, x0: 32)
        y2 = _scale(dst, top, y1, rotate: rotate_top, scale_x: scale_x, scale_y: scale_y, x0: 32)
      end

      mask!(dst, y2) if y2 <= 0
    end

    dst.save dst_fname
    puts "[*] => #{dst_fname}" if @debug
  end

  def self.convert_args! args, name, flat: false, debug: false, extra_tex: {}, faces: nil
    faces ||= {}
    if args[:texture] == args[:top]
      args.delete(:texture)
    end

    if debug
      puts "[d] #{name}: flat=#{flat} faces=#{faces && faces.size} args:"
      pp args
      puts "[d] faces:"
      pp faces
    end

    # flatten
    if args.values.uniq.size == 1 && args.size > 1
      args = {all: args.values.first}
    end

    if !args[:top]
      args[:top] ||= args.delete(:all)
      args[:top] ||= args.delete(:texture)
      if !args[:top]
        puts "[!] #{name}: no top texture".red
        return
      end
    end

    dst_dir = File.join("Textures", "Blocky", name[0].upcase)
    FileUtils.mkdir_p dst_dir
    dst_fname = File.join(dst_dir, name.camelize) + ".png"

    c = TextureConverter.new( debug: debug, extra_tex: extra_tex )

    #puts "[.] #{args}"

    rot_per_side = { east: 90, west: 270, north: 180, south: 0 }

    nsides = 0
    a1 = args.dup
    [:east, :north, :south, :west].each do |side|
      if args[side]
        dst_side_fname = dst_fname.sub(".png", "_#{side}.png")
        face = faces[side.to_s] || {}

        c.convert!(
          top: args[:top],
          side: args[side],
          dst_fname: dst_side_fname,
          rotate_top: rot_per_side[side],
          rotate_front: face['rotation'].to_i,
          flat: flat,
          scale_x: face[:scale_x],
          scale_y: face[:scale_y],
        )

        a1.delete(side)
        nsides += 1
      end
    end

    return if nsides == 4

    if a1 != args
      raise args.inspect if a1.keys != [:top]
      return
    end

    case args.size
    when 1
      flat = true # XXX make it always flat
      if flat
        c.convert!(top: args[:top], dst_fname: dst_fname, flat: true)
      else
        c.convert!(top: args[:top], front: args[:top], dst_fname: dst_fname)
      end
    when 2
      c.convert!(**args, dst_fname: dst_fname)
    when 3
      c.convert!(top: args[:top], front: args[:front], dst_fname: dst_fname.sub(".png", "_south.png"))
      c.convert!(top: args[:top], side: args[:side], dst_fname: dst_fname.sub(".png", "_west.png"), rotate_top: 90)
    when 4
      c.convert!(top: args[:top], front: args[:front], dst_fname: dst_fname.sub(".png", "_south.png"))
      c.convert!(top: args[:top], side: args[:side], dst_fname: dst_fname.sub(".png", "_west.png"), rotate_top: 90)
      c.convert!(top: args[:top], front: args[:back], dst_fname: dst_fname.sub(".png", "_north.png"), rotate_top: 180)
    else
      raise args.inspect
    end
  rescue
    STDERR.puts "[!] error processing #{name} (#{args.inspect})".red
    raise
  end # self.convert_args!

  SCALE_X = 4
  SCALE_Y = 2

  def initialize debug: false, extra_tex: {}
    @debug = debug
    @extra_tex = extra_tex
  end

  def _scale dst, fname, y0, x0: 0, scale_x: SCALE_X, scale_y: SCALE_Y, rotate: 0
    src = fname.is_a?(Image) ? fname : Image.new(File.open(fname,"rb"))

    if src.width < 16 || src.height < 16
      puts "[?] unexpected image size: #{src.width}x#{src.height}".yellow
      return nil
    end

    rotate = rotate.to_i
    raise "invalid rotate" if rotate%90 != 0
    while rotate != 0
      src = src.rotated_90_cw
      rotate -= 90
    end

    begun = false
    ntrans = 0
    nscan = 0
    y = y0
    src.scanlines.reverse.each do |sl|
      nscan += 1
      break if nscan > 16 || y < 0
      all_trans = sl.pixels.all?(&:transparent?)
      next if all_trans
      scale_y.times do
        if all_trans
          ntrans += 1
        else
          ntrans = 0
          begun = true
          sl.each_pixel do |c, x|
            next if c.transparent?
            scale_x.times do |ix|
              dst[x0+x*scale_x+ix, y] = c
            end
          end
        end
        y -= 1
      end
    end
    y
  end

  def mask! dst, y0
    y0 = 0 if y0 == -1
    @@mask ||= Image.new(File.open("../mask4.png","rb"))
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

  def normalize_rotate x
    x = x.to_i
    x %= 360
    x += 360 if x < 0
    raise "invalid rotate: #{x}" if x%90 != 0
    x
  end

end
