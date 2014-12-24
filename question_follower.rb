require_relative 'questions'

class QuestionFollower

  include Saveable

  attr_accessor :id, :question_id, :user_id

  def initialize(options = {})
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end

  def self.find_by_id(id)
    results = QuestionDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      question_followers
    WHERE
      id = ?
    SQL

    results.map { |result| QuestionFollower.new(result)}[0]
  end

  def self.followers_for_question_id(question_id)
    results = QuestionDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      users.id, users.fname, users.lname
    FROM
      question_followers JOIN users
      ON user_id = users.id
    WHERE
      question_id = ?
    SQL

    results.map { |result| User.new(result) }
  end

  def self.followed_questions_for_user_id(user_id)
    results = QuestionDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      q.id, q.title, q.body, q.author_id
    FROM
      question_followers JOIN questions q
      ON question_id = q.id
    WHERE
      user_id = ?
    SQL

    results.map { |result| Question.new(result) }
  end

  def self.most_followed_questions(n)
    results = QuestionDatabase.instance.execute(<<-SQL)
    SELECT
      q.id, q.title, q.body, q.author_id
    FROM
      question_followers JOIN questions q
      ON question_id = q.id
    GROUP BY
      question_id
    ORDER BY
      COUNT(question_id) DESC
    SQL

    results.map { |result| Question.new(result) }[0...n]
  end


end
