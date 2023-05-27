# frozen_string_literal: true
require 'active_support/core_ext/string'
require 'digest/md5'
require 'zpng'
require 'set'

require_relative 'def_maker'

class DoorMaker < DefMaker
  include ZPNG

  TEX_REL_PATH = "Textures/Blocky/Doors"

  def initialize assets_dir
    super()
    @assets_dir = assets_dir
  end

  def process!
    FileUtils.mkdir_p TEX_REL_PATH
    Dir[File.join(@assets_dir, "minecraft/textures/block/*_door_top.png")].each do |top_fname|
      name = File.basename(top_fname).split(/_top.png/).first.camelize
      puts "[.] #{name}"
      bottom_fname = top_fname.sub("_top.png", "_bottom.png")
      dst = Image.new :width => 64, :height => 64

      src = Image.new(File.open(top_fname, "rb"))
      src.each_pixel do |c,x,y|
        dst[x*2+0, y*2+0] = c
        dst[x*2+1, y*2+0] = c
        dst[x*2+0, y*2+1] = c
        dst[x*2+1, y*2+1] = c
      end

      src = Image.new(File.open(bottom_fname, "rb"))
      src.each_pixel do |c,x,y|
        dst[x*2+0, 32+y*2+0] = c
        dst[x*2+1, 32+y*2+0] = c
        dst[x*2+0, 32+y*2+1] = c
        dst[x*2+1, 32+y*2+1] = c
      end

      # vertical middle border
      64.times do |y|
        dst[32, y] = Color::BLACK
        dst[33, y] = Color::BLACK
      end

      # horizontal top and bottom half borders
      32.times do |x|
        dst[x,  0] = Color::BLACK
        dst[x,  1] = Color::BLACK
        dst[x, 62] = Color::BLACK
        dst[x, 63] = Color::BLACK
      end

      fname = File.join(TEX_REL_PATH, name + "_Mover.png")
      dst.save(fname)
      texPath = fname.sub(".png","").sub(/^Textures\//, "")

      # mirror left side to right side
      64.times do |y|
        32.times do |x|
          dst[64-x,y] = dst[x,y]
        end
      end

      fname = File.join(TEX_REL_PATH, name + "_MenuIcon.png")
      dst.save(fname)
      uiIconPath = fname.sub(".png","").sub(/^Textures\//, "")

      designator = "Blocky_Props_Doors"
      add_designator(designator)

      label = name.underscore.humanize.downcase
      add_def <<~EOF
        <ThingDef Name="Blocky_Props_#{name}" ParentName="Blocky_Props_Base_Door">
          <defName>Blocky_Props_#{name}</defName>
          <label>#{label}</label>
          <graphicData>
            <texPath>#{texPath}</texPath>
          </graphicData>
          <designatorDropdown>#{designator}</designatorDropdown>
          <uiIconPath>#{uiIconPath}</uiIconPath>
        </ThingDef>
      EOF
    end

    write! "Defs/Doors.xml"
  end
end
