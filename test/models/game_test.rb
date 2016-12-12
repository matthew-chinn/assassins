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

end
