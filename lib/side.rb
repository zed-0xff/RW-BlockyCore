# frozen_string_literal: true

class Side
  attr_reader :name, :rotation, :axes

  def initialize name, rotation, axes
    @name = name
    @rotation = rotation
    @axes = axes
  end

  NORTH = new('north', 180, [0, 1])
  SOUTH = new('south',   0, [0, 1])
  EAST  = new('east',   90, [2, 1])
  WEST  = new('west',  270, [2, 1])
  UP    = new('up',      0, [0, 2])

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
  end
end
