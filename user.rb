require_relative 'questions'

class User

  include Saveable

  attr_accessor :id, :fname, :lname

  def initialize(options = {})
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def self.find_by_id(id)
    results = QuestionDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      users
    WHERE
      id = ?
    SQL

    results.map { |result| User.new(result)}[0]
  end

  def self.find_by_name(fname, lname)
    results = QuestionDatabase.instance.execute(<<-SQL, fname, lname)
    SELECT
      *
    FROM
      users
    WHERE
      fname = ? AND lname = ?
    SQL

    results.map { |result| User.new(result)}[0]
  end

  def authored_questions
    Question.find_by_author_id(id)
  end

  def authored_replies
    Reply.find_by_author_id(id)
  end

  def followed_questions
    QuestionFollower.followed_questions_for_user_id(id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(id)
  end

  def average_karma
    results = QuestionDatabase.instance.execute(<<-SQL, self.id)
    SELECT
      CAST(num_likes AS FLOAT) / num_questions
    FROM
      (
        SELECT
          COUNT(DISTINCT(questions.id)) num_questions, COUNT(likes.question_id) num_likes
        FROM
          questions LEFT OUTER JOIN question_likes likes
          ON questions.id = likes.question_id
        WHERE
          questions.author_id = ?
      )
    SQL

  end

end

test = User.new('id' => nil, 'fname' => 'TEST', 'lname' => 'ING')
test.save
