# frozen_string_literal: true
require 'json'
require 'zpng'

require_relative 'config'

include ZPNG

class ZPNG::Image
  def to_grayscale
    img = dup
    avg2 = img.pixels.find_all{ |p| !p.transparent? && !p.black? }.map(&:to_grayscale)
    avg2 = avg2.inject(:+) / avg2.size

    corr = avg2 < 128 ? (128-avg2)*2 : 0

    a = [0]*16
    img.each_pixel do |c,x,y|
      next if c.transparent? || c.black?

      g = [c.to_grayscale + corr, 255].min
      img[x,y] = Color.new(g,g,g, c.alpha)
      a[g/16] += 1
    end
#    avg = 0
#    n = 0
#    a.each_with_index do |x,i|
#      avg += x*i
#      n += i
#    end
#    avg /= n
#    printf "[.] %s avg=%3d avg2=%3d\n", a.map{ |x| "%4d" % x }.join(' '), avg, avg2
    img
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
