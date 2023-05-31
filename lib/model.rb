#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'zpng'

require_relative 'config'
require_relative 'side'

class Model
  include ZPNG

  CACHE = {}
  CUSTOM_RENDERERS = {}

  attr_reader :key, :textures, :elements
  attr_accessor :render_type, :abstract, :debug

  def initialize key, data
    #@data = data
    @key = key.sub('minecraft:', '')
    @parent_key = data['parent']&.sub('minecraft:', '')
    @textures = data['textures'].dup || {}
    @elements = data['elements'].dup || []
    @abstract = false
    name = @key.sub("block/", "")
    @render_type = CONFIG.render_types.find{ |x| x[0].match(name) }&.last&.to_sym
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
    render_side(Side.up).rotated(for_side.rotation)
  end

  def render_side side, tex_root: self, elements: self.elements
    raise "Side expected" unless side.is_a?(Side)

    img = parent ? parent.render_side(side, tex_root: tex_root) : Image.new(width: 16, height: 16)
    return nil if img.nil?

    els = elements #.sort_by{|el| el.dig('to', 1) } # kinda z-index
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

          if dh < 16
            dy1 = 16-dy-dh
            #puts "[d] dy=#{dy}, dh=#{dh} => #{dy1}"
            dy = dy1
            #sy = 16-sy-sh
          end

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

          # XXX do we need to mirror if coords are in reverse order?

          subtex = tex.cropped x: sx, y: sy, width: sw, height: sh
          subtex = subtex.rotated(face['rotation']) if face['rotation']
          img.copy_from(subtex, dst_x: dx, dst_y: dy, dst_width: dw, dst_height: dh)
#          img.copy_from(tex,
#                        src_x: sx,     src_y: sy,
#                        dst_x: dx,     dst_y: dy,
#                        src_width: sw, src_height: sh,
#                        dst_width: dw, dst_height: dh,
#                       )
        else
          tex = tex.rotated(face['rotation']) if face['rotation']
          img.copy_from(tex)
        end
      end
    end

    if img.pixels.all?(&:transparent?) && textures['particle'] && tex_root == self
      tex = resolve_and_load_texture(textures['particle'], tex_root)
      return nil if tex.nil? && @abstract

      img.copy_from(tex)
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
  key = "block/#{key}" unless key['block/']
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
    img = m.render_side(Side[d]).scaled(4)
    img.save "#{d}.png"
    puts "[=] #{d}.png"
  end
end
