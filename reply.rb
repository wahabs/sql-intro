require_relative 'questions'

class Reply

  include Saveable

  attr_accessor :id, :question_id, :user_id, :parent_id, :body

  def initialize(options = {})
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
    @parent_id = options['parent_id']
    @body = options['body']
  end

  def self.find_by_id(id)
    results = QuestionDatabase.instance.execute(<<-SQL, id)
    SELECT
    *
    FROM
    replies
    WHERE
    id = ?
    SQL

    results.map { |result| Reply.new(result)}[0]
  end

  def self.find_by_question_id(question_id)
    results = QuestionDatabase.instance.execute(<<-SQL, question_id)
    SELECT
    *
    FROM
    replies
    WHERE
    question_id = ?
    SQL

    results.map { |result| Reply.new(result)}
  end

  def self.find_by_user_id(user_id)
    results = QuestionDatabase.instance.execute(<<-SQL, user_id)
    SELECT
    *
    FROM
    replies
    WHERE
    user_id = ?
    SQL

    results.map { |result| Reply.new(result)}
  end

  def author
    results = QuestionDatabase.instance.execute(<<-SQL, user_id)
    SELECT
    *
    FROM
    users
    WHERE
    id = ?
    SQL

    results.map { |result| User.new(result)}
  end

  def question
    results = QuestionDatabase.instance.execute(<<-SQL, user_id)
    SELECT
    *
    FROM
    questions
    WHERE
    id = ?
    SQL

    results.map { |result| Question.new(result)}
  end

  def parent_reply
    results = QuestionDatabase.instance.execute(<<-SQL, parent_id)
    SELECT
    *
    FROM
    replies
    WHERE
    id = ?
    SQL

    results.map { |result| Reply.new(result)}
  end

  def child_replies
    results = QuestionDatabase.instance.execute(<<-SQL, id)
    SELECT
    *
    FROM
    replies
    WHERE
    parent_id = ?
    SQL

    results.map { |result| Reply.new(result)}
  end

end
