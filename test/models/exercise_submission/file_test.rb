require "test_helper"

class ExerciseSubmission::FileTest < ActiveSupport::TestCase
  test "validates presence of exercise_submission" do
    file = build(:exercise_submission_file, exercise_submission: nil)

    refute file.valid?
    assert_includes file.errors[:exercise_submission], "must exist"
  end

  test "validates presence of filename" do
    file = build(:exercise_submission_file, filename: nil)

    refute file.valid?
    assert_includes file.errors[:filename], "can't be blank"
  end

  test "validates presence of digest" do
    file = build(:exercise_submission_file, digest: nil)

    refute file.valid?
    assert_includes file.errors[:digest], "can't be blank"
  end

  test "has Active Storage attachment for content" do
    file = create(:exercise_submission_file)

    assert file.content.attached?
  end
end
