# frozen_string_literal: true

class Side
  attr_reader :name, :rotation, :axes, :z_sort_proc

  def initialize name, rotation, axes, z_sort_proc
    @name = name.freeze
    @rotation = rotation.freeze
    @axes = axes.freeze
    @z_sort_proc = z_sort_proc.freeze
  end

  # XXX very likely not all z_sort_proc funcs are the right ones
  NORTH = new('north', 180, [0, 1], Proc.new{|el| el.dig('to', 2) } ).freeze
  SOUTH = new('south',   0, [0, 1], Proc.new{|el| el.dig('to', 2) } ).freeze
  EAST  = new('east',   90, [2, 1], Proc.new{|el| el.dig('to', 2) } ).freeze
  WEST  = new('west',  270, [2, 1], Proc.new{|el| el.dig('to', 2) } ).freeze
  UP    = new('up',      0, [0, 2], Proc.new{|el| el.dig('to', 1) } ).freeze

  ALL = [UP, NORTH, SOUTH, EAST, WEST].freeze

  def to_sym
    @name.to_sym
  end

  def to_s
    @name
  end

  def north?; self == NORTH; end
  def south?; self == SOUTH; end
  def east?;  self == EAST; end
  def west?;  self == WEST; end
  def up?;    self == UP; end

  class << self
    def north; NORTH; end
    def south; SOUTH; end
    def east; EAST; end
    def west; WEST; end
    def up; UP; end

    def [] x
      send(x)
    end

    def all
      ALL
    end

    def each &block
      [UP, NORTH, SOUTH, EAST, WEST].each(&block)
    end

    def each_nsew &block
      [NORTH, SOUTH, EAST, WEST].each(&block)
    end
  end
end
