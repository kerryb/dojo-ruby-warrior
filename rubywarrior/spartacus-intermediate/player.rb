class State
  def initialize player
    @player = player
  end

  def method_missing name, *args
    @player.send name, *args
  end
end

class LookForGloryState < State
  def call
    glory = listen[0]
    if feel( direction_of(glory) ).stairs?
      avoid_stairs
    else
      walk! direction_of(glory)
    end
  end
end

class Player
  def initialize
    @states = {
      look_for_glory: LookForGloryState.new(self),
    }
  end

  def play_turn(warrior)
    @warrior = warrior

    @ticking_spaces = listen_for_ticking
    @enemy_directions = detect :enemy?
    @captive_directions = detect :captive?
    if outnumbered?
      bind! first_enemy_direction_not_towards_ticking
    elsif @ticking_spaces.size > 0
      deal_with_ticking
    elsif @enemy_directions.size == 1
      attack!(@enemy_directions[0])
    elsif health < 20
      rest!
    elsif captives?
    rescue!(@captive_directions[0])
    elsif listen.size > 0
      @states[:look_for_glory].call
    else
      walk! direction_of_stairs
    end
  end

  private

  def listen_for_ticking
    listen.select { |space| space.ticking? }
  end

  def first_enemy_direction_not_towards_ticking
    ticking_directions = @ticking_spaces.map {|s| direction_of s }
    @enemy_directions.detect {|direction| !ticking_directions.include? direction }
  end

  def deal_with_ticking
    ticking_direction = direction_of(@ticking_spaces[0])
    space = feel(ticking_direction)

    if space.enemy?
      if look.select(&:enemy?).size > 1
        detonate! ticking_direction
      else
        attack! ticking_direction
      end
    elsif space.stairs?
      avoid_stairs
    elsif space.captive?
    rescue! ticking_direction
    else
      if listen.select {|s| s.enemy? && distance_of(s) <= 2 }.size > 1
        if health > 4
          detonate! ticking_direction
        else
          rest!
        end
      else
        walk! ticking_direction
      end
    end
  end

  def detect type
    [:forward,:backward,:left,:right].select { |direction|
      feel(direction).send(type)
    }
  end

  def outnumbered?
    @enemy_directions.size > 1
  end

  def captives?
    @captive_directions.size > 0
  end

  def avoid_stairs
    empty_spaces = detect :empty?
    if feel(empty_spaces[0]).stairs?
      walk! empty_spaces[1]
    else
      walk! empty_spaces[0]
    end
  end

  def method_missing name, *args
    @warrior.send name, *args
  end
end
