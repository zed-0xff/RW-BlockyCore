# frozen_string_literal: true
require 'json'
require 'zpng'

require_relative 'config'
require_relative 'mc'

include ZPNG

# r = (r1/255.0) / (r2/255.0)

class ZPNG::Image
  def avg_color
    ar = []
    ag = []
    ab = []
    pixels.find_all{ |p| !p.transparent? && !p.black? }.each do |p|
      ar << p.r
      ag << p.g
      ab << p.b
    end
    Color.new(
      ar.inject(:+) / ar.size,
      ag.inject(:+) / ag.size,
      ab.inject(:+) / ab.size
    )
  end

  def fill! x:, y:, width:, height:, color:
    height.times do |i|
      width.times do |j|
        self[x+j, y+i] = color
      end
    end
    self
  end

  def to_grayscale
    img = dup
    avgc = avg_color

    img.each_pixel do |c,x,y|
      next if c.transparent? || c.black?

      img[x,y] = Color.from_grayscale((c).to_grayscale)
    end
    img
  end

  AVG_STUFF_COLORS = {
    "acacia"   => Color.from_html('A85A32'),  # <color>(223, 119, 66)</color>
    "birch"    => Color.from_html('C0AF79'),  # <color>(255, 232, 160)</color>
    "crimson"  => Color.from_html('653046'),  # <color>(134, 63, 92)</color>
    "dark_oak" => Color.from_html('422B14'),  # <color>(87, 57, 26)</color>
    "jungle"   => Color.from_html('A07350'),  # <color>(212, 152, 106)</color>
    "mangrove" => Color.from_html('753630'),  # <color>(155, 71, 63)</color>
    "oak"      => Color.from_html('A2824E'),  # <color>(215, 172, 103)</color>
    "spruce"   => Color.from_html('725430'),  # <color>(151, 111, 63)</color>
    "warped"   => Color.from_html('2B6863'),  # <color>(57, 138, 131)</color>
  }

  def to_stuffable name = nil
    ac = nil
    if name
      ac = AVG_STUFF_COLORS.find{ |k,v| name.downcase[k] }&.last
    end
    ac ||= avg_color
    self/(ac/CONFIG.stuffable_color_corr)
  end

  def add_border
    img = dup
    img.width.times do |x|
      img[x, 0] = Color::BLACK
      img[x, img.height-1] = Color::BLACK
    end
    img.height.times do |y|
      img[0, y] = Color::BLACK
      img[img.width-1, y] =  Color::BLACK
    end
    img
  end

  def inline!
    shadow = Color.new(0,0,0,107)

    height.times do |y|
      width.times do |x|
        c = self[x,y]
        next if c.transparent? || c == shadow
        
        self[x-1,y] = shadow
        self[x,y]   = Color::BLACK
        self[x+1,y] = Color::BLACK
        break
      end

      (width-1).downto(0) do |x|
        c = self[x,y]
        next if c.transparent? || c == shadow
        
        self[x-1,y] = Color::BLACK
        self[x,y]   = Color::BLACK
        self[x+1,y] = shadow
        break
      end
    end

    width.times do |x|
      height.times do |y|
        c = self[x,y]
        next if c.transparent? || c == shadow
        
        self[x,y+1] = Color::BLACK
        self[x,y]   = Color::BLACK
        self[x,y-1] = shadow
        break
      end

      (height-1).downto(0) do |y|
        c = self[x,y]
        next if c.transparent? || c == shadow
        
        self[x,y-1] = Color::BLACK
        self[x,y]   = Color::BLACK
        self[x,y+1] = shadow
        break
      end
    end

    self
  end
end
