require 'test_helper'

class GameTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "Game.possible_to_match_all?" do
      assert_not Game.possible_to_match_all?([10,5,3])
      assert Game.possible_to_match_all?([10,5,5])
      assert_not Game.possible_to_match_all?([10])
  end

  test "Game.assign_targets" do
      g = Game.first
      set = g.assign_targets
      if set.count == 0
          puts "Empty set"
      end

      set.each do |edge|
          puts edge.to_s
      end
  end

end
