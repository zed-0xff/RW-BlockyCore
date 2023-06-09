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

  def released? *args
    true
  end

  def render_mover top_fname
    bottom_fname = top_fname.sub("_top.png", "_bottom.png")
    dst = Image.new :width => 64, :height => 64

    src = Image.new(File.open(top_fname, "rb"))
    dst.copy_from src, dst_width: 32, dst_height: 32

    src = Image.new(File.open(bottom_fname, "rb"))
    dst.copy_from src, dst_width: 32, dst_height: 32, dst_y: 32

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
    dst
  end

  def render_icon dst
    # mirror left side to right side
    64.times do |y|
      32.times do |x|
        dst[64-x,y] = dst[x,y]
      end
    end
    dst
  end

  def render_nonstuffable top_fname
    name = File.basename(top_fname).split(/_top.png/).first.camelize
    puts "[.] #{name}"

    dst = render_mover(top_fname)
    fname = File.join(TEX_REL_PATH, name + "_Mover.png")
    dst.save(fname)
    texPath = fname.sub(".png","").sub(/^Textures\//, "")

    dst = render_icon(dst)
    fname = File.join(TEX_REL_PATH, name + "_MenuIcon.png")
    dst.save(fname)
    uiIconPath = fname.sub(".png","").sub(/^Textures\//, "")

    designator = "Blocky_Props_Doors"
    add_designator(designator)

    label = name.underscore.humanize.downcase
    add_def <<~EOF
        <ThingDef Name="Blocky_Props_#{name}" ParentName="Blocky_Props_DoorBase_NonStuffable">
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

  def render_stuffable top_fname
    name = File.basename(top_fname).split(/_top.png/).first.camelize
    puts "[.] #{name}"

    dst = render_mover(top_fname).to_grayscale
    fname = File.join(TEX_REL_PATH, name + "_Stuffable_Mover.png")
    dst.save(fname)
    texPath = fname.sub(".png","").sub(/^Textures\//, "")

    dst = render_icon(dst).to_grayscale
    fname = File.join(TEX_REL_PATH, name + "_Stuffable_MenuIcon.png")
    dst.save(fname)
    uiIconPath = fname.sub(".png","").sub(/^Textures\//, "")

    designator = "Blocky_Props_Doors"
    add_designator(designator)

    title = name.underscore.humanize.downcase.sub(/door$/, "").strip.titleize
    label = "\"#{title}\" door"
    # XXX should not have designatorDropdown, affects Blocky.Doors!
    add_def <<~EOF
        <ThingDef Name="Blocky_Props_#{name}_Stuffable" ParentName="Blocky_Props_DoorBase">
          <defName>Blocky_Props_#{name}_Stuffable</defName>
          <label>#{label}</label>
          <graphicData>
            <texPath>#{texPath}</texPath>
          </graphicData>
          <designatorDropdown>#{designator}</designatorDropdown>
          <uiIconPath>#{uiIconPath}</uiIconPath>
        </ThingDef>
    EOF

#    src = Image.new(File.open(top_fname, "rb"))
#    thr = 5
#    all_gray = src.pixels.all?{ |c| (c.r - c.g).abs <= thr && (c.g - c.b).abs <= thr }
#    puts "[d] #{top_fname}: #{all_gray}"
  end

  def process_item top_fname
    render_nonstuffable top_fname
    render_stuffable top_fname
  end

  def process!
    FileUtils.mkdir_p TEX_REL_PATH
    Dir[File.join(@assets_dir, "minecraft/textures/block/*_door_top.png")].each do |top_fname|
      process_item top_fname
    end

    convert_designators!
    write_defs! "Defs/Doors.xml"
  end
end
