#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'common'
require_relative 'side'

class Model
  include ZPNG

  CACHE = {}
  CUSTOM_RENDERERS = {}

  attr_reader :key, :textures, :elements, :name
  attr_accessor :render_types, :abstract, :debug

  def initialize key, data
    #@data = data
    @key = key.sub('minecraft:', '')
    @parent_key = data['parent']&.sub('minecraft:', '')
    @textures = data['textures'].dup || {}
    @elements = data['elements'].dup || []
    @abstract = false
    @name = @key.sub("block/", "")
    rtypes = CONFIG.render_types.find{ |x| x[0].match(@key) }&.last
    case rtypes
    when Hash
      @render_types = rtypes.map{ |k,v| [k, v] }.to_h
    when String
      @render_types = { "" => rtypes }
    when nil
    else
      raise "unexpected render type(s): #{rtypes}"
    end
  end

  def render_type= rtype
    @render_types = { "" => rtype }
  end

  def abstract?
    @abstract
  end

  def self.renders *keys
    keys.each do |k|
      CUSTOM_RENDERERS[k] = self
    end
  end

  def parent
    @parent_key && Model.find(@parent_key)
  end

  def self.find key
    key = key.sub('minecraft:', '')
    CACHE[key] ||= _load(key)
  end

  def self._load key
    return nil if key['builtin/']
    fname = File.join(CONFIG.assets_dir, "minecraft", "models", key) + ".json"
    klass = CUSTOM_RENDERERS[key] || Model
    klass.new(key, JSON.load_file(fname))
  end

  def _convert_uv fname, uv
    w = [(uv[2]-uv[0]).abs + 1, 16].min
    h = [(uv[3]-uv[1]).abs + 1, 16].min
    puts "[d] _convert_uv: w=#{w} h=#{h}" if @debug

    return fname if w == 16 && h == 16

    dst = Image.load(fname)
      .crop(x: uv[0], y:uv[1], width: w, height: h.abs)
    # TODO: mirror if negative h
    #dst.save "uv_#{w}x#{h}.png"
    dst
  end

  @@cached_textures = {}

  def resolve_and_load_texture tex_key, tex_root
    tex_key = tex_root.resolve_texture(tex_key)
    return load_texture(tex_key) if tex_key[0] != '#'

    if tex_key != "#pattern"
      tex_key2 = tex_root.resolve_texture("#pattern")
      return load_texture(tex_key2) if tex_key2[0] != '#'
    end

    if @abstract
      return nil
    else
      raise NoTextureError.new("no texture #{tex_key}")
    end
  end

  def load_texture tex_key
    @@cached_textures[tex_key] ||=
      Image.load( File.join(CONFIG.assets_dir, "minecraft", "textures", tex_key.sub('minecraft:', '')) + ".png" )
  end

  class NoTextureError < StandardError; end

  def render_top for_side
    render_side(Side.up)&.rotated(for_side.rotation)
  end

  def render_side side, tex_root: self, elements: self.elements
    raise "Side expected" unless side.is_a?(Side)

    img = parent ? parent.render_side(side, tex_root: tex_root) : Image.new(width: 16, height: 16)
    return nil if img.nil?

    if textures.keys == ['cross'] # brown_mushroom, red_mushroom
      return nil if side.up?
      tex = resolve_and_load_texture(textures.values.first, tex_root)
      img.copy_from tex
      return img
    end

    # kinda z-index
    els = elements.sort_by(&side.z_sort_proc)
    els.each do |el|
      if (face = el.dig('faces', side.to_s))
        tex = resolve_and_load_texture(face['texture'], tex_root)
        return nil if tex.nil? && @abstract

        if (uv=face['uv']) || el['from']
          ax1, ax2 = side.axes
          dx = el.dig('from', ax1).to_i # can be a float! x_x
          dy = el.dig('from', ax2).to_i
          dw = [el.dig('to', ax1) - el.dig('from', ax1), 16].min.to_i
          dh = [el.dig('to', ax2) - el.dig('from', ax2), 16].min.to_i

          # original coords are from bottom left corner, but ZPNG's are from top left
          dy = 16-dy-dh if dh < 16

          sx = dx
          sy = dy
          sw = dw
          sh = dh
          if uv
            sx = [uv[0], uv[2]].min.to_i
            sy = [uv[1], uv[3]].min.to_i
            sx2 = [uv[0], uv[2]].max.to_i
            sy2 = [uv[1], uv[3]].max.to_i
            sw = sx2-sx+1
            sh = sy2-sy+1
          end

          if @debug
            printf("[d] sx=%2d sy=%2d sw=%2d sh=%2d => dx=%2d dy=%2d dw=%2d dh=%2d tex=%-10s from=%-10s to=%-10s\n",
                   sx, sy, sw, sh,
                   dx, dy, dw, dh,
                   face['texture'], el['from'], el['to']
                  )
          end

          subtex = tex.cropped x: sx, y: sy, width: sw, height: sh
          subtex = subtex.rotated(face['rotation']) if face['rotation']
          img.copy_from(subtex, dst_x: dx, dst_y: dy, dst_width: dw, dst_height: dh)
        else
          tex = tex.rotated(-face['rotation']) if face['rotation']
          img.copy_from(tex)
        end
      end
    end

    if img.pixels.all?(&:transparent?) && tex_root == self
      if textures.size == 1
        return nil if ['cross', 'crop'].include?(textures.keys.first) && side.up?

        tex = resolve_and_load_texture(textures.values.first, tex_root)
        img.copy_from(tex)
        return img unless img.pixels.all?(&:transparent?)
      end

      %w'particle layer0'.each do |t|
        if textures[t]
          tex = resolve_and_load_texture(textures[t], tex_root)
          next if !tex
          img.copy_from(tex)
          return img unless img.pixels.all?(&:transparent?)
        end
      end
      return nil
    end

    img
  end

  def resolve_texture id
    return nil unless id
    while id[0] == '#'
      if (id2 = textures[id[1..-1]])
        id = id2
      elsif parent
        id2 = parent.resolve_texture(id)
        break if id2 == id
        id = id2
      else
        break
      end
    end
    id
  end
end

Dir[File.join(File.dirname(__FILE__), "model", "*.rb")].each do |fn|
  require fn
end

if __FILE__ == $0
  key = ARGV.first
  key = "block/#{key}" unless key['/']
  m = Model.find key
  m.debug = true

  x = m
  a = []
  while x
    a << x
    x = x.parent
  end
  a.reverse.each{ |x| pp x }
  
  sides = %w'up north south east west'
  if ARGV[1]
    sides = [ARGV[1]]
  end
  sides.each do |d|
    img = m.render_side(Side[d])&.scaled(4)
    next unless img

    img.save "#{d}.png"
    puts "[=] #{d}.png"
  end
end
