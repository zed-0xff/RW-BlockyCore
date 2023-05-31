#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'zpng'

require_relative 'config'

class Model
  include ZPNG

  CACHE = {}

  attr_reader :key, :textures, :elements
  attr_accessor :render_type, :abstract

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

  def parent
    @parent_key && Model.find(@parent_key)
  end

  def self.find key
    key = key.sub('minecraft:', '')
    CACHE[key] ||= _load(key)
  end

  def self._load key
    fname = File.join(CONFIG.assets_dir, "minecraft", "models", key) + ".json"
    Model.new(key, JSON.load_file(fname))
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

  SIDE2AXIS = {
    up:    [0, 2],
    north: [0, 1],
    south: [0, 1],
    east:  [2, 1],
    west:  [2, 1],
  }

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

  def render_side side, tex_root = self
    img = parent ? parent.render_side(side, tex_root) : Image.new(width: 16, height: 16)
    return nil if img.nil?

    elements.each do |el|
      if (face = el.dig('faces', side.to_s))
        tex = resolve_and_load_texture(face['texture'], tex_root)
        return nil if tex.nil? && @abstract

        if (uv=face['uv']) || el['from']
          uv ||= [0, 0, 16, 16]
          ax1, ax2 = SIDE2AXIS[side.to_sym]
          sw = [(uv[2]-uv[0]).abs + 1, 16].min.to_i
          sh = [(uv[3]-uv[1]).abs + 1, 16].min.to_i
          dx = el.dig('from', ax1).to_i # might be a float! x_x
          dy = el.dig('from', ax2).to_i
          dw = [el.dig('to', ax1) - el.dig('from', ax1) + 1, 16].min.to_i
          dh = [el.dig('to', ax2) - el.dig('from', ax2) + 1, 16].min.to_i
          sx = [uv[0], uv[2]].min.to_i
          sy = [uv[1], uv[3]].min.to_i # XXX do we need to mirror if coords are in reverse order?

          # HACK: stonecutter
          next if face['texture'] == "#saw"

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

    if elements.empty? && textures['particle'] && tex_root == self
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

if __FILE__ == $0
  key = ARGV.first
  key = "block/#{key}" unless key['block/']
  m = Model.find key

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
    img = m.render_side(d).scaled(4)
    img.save "#{d}.png"
    puts "[=] #{d}.png"
  end
end

Dir[File.join(File.dirname(__FILE__), "model", "*.rb")].each do |fn|
  require fn
end
