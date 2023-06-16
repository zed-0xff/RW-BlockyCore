#!/usr/bin/env ruby
require_relative 'lib/common'
include ZPNG

mc_colors = {
  acacia: 'd87f33',
  birch: 'f7e9a3',
  crimson: '943f61',
  dark_oak: '664c33',
  jungle: '976d4d',
  mangrove: '993333',
  oak: '8f7748',
  spruce: '815631',
  warped: '3a8e8c'
}

woods = mc_colors.keys

dst = Image.new((woods.size*2+2)*16, (woods.size*2+2)*16)
srcs = {}

@texcache = {}
def load_tex name
  @texcache[name] ||=
    Image.load(File.expand_path("~/games/minecraft/assets/minecraft/textures/block/#{name}_planks.png"))
end

@avgcolors = {}
def avg_color tex
  @avgcolors[tex] ||= tex.avg_color
end

corr = CONFIG.stuffable_color_corr

woods.each_with_index do |name, i|
  src = load_tex(name)
  dst.copy_from src, dst_y: (i+1)*16
  dst.copy_from src, dst_y: (i+1+woods.size)*16+2
  dst.copy_from src, dst_x: (i+1)*16
  dst.copy_from src, dst_x: (i+1+woods.size)*16+2

  avgc = avg_color(src)
  mc_color = Color.from_html(mc_colors[name])

  stuff_color = avgc/corr
  printf "  %-10s => Color.from_html('%s'),  # <color>(%d, %d, %d)</color>\n", name.to_s.inspect, avgc,
    stuff_color.r, stuff_color.g, stuff_color.b

  woods.each_with_index do |name2, j|
    mc_color2 = Color.from_html(mc_colors[name2])
    src2 = load_tex(name2)
    avgc2 = avg_color(src2)
    dst.copy_from src.divmul(avgc, avgc2),
      dst_x: (j+1)*16,
      dst_y: (i+1)*16
    dst.copy_from src/(avgc/corr)*(avgc2/corr),
      dst_x: (j+1+woods.size)*16+2,
      dst_y: (i+1)*16
    dst.copy_from src/(mc_color/corr)*mc_color2,
      dst_x: (j+1)*16,
      dst_y: (i+1+woods.size)*16+2
    dst.copy_from src/(mc_color/corr)*(mc_color2/corr),
      dst_x: (j+1+woods.size)*16+2,
      dst_y: (i+1+woods.size)*16+2
  end
end

dst.scale(2).save "1.png"
