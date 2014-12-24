require 'singleton'
require 'sqlite3'




class QuestionDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.results_as_hash = true
    self.type_translation = true
  end

end

class Saving

  def get_variables
    values = {}
    self.instance_variables.each do |instant_var|
      values[instant_var] = self.instance_variable_get(instant_var)
    end
    values
  end

  def my_table
    class_to_table = {'User' => 'users', 'Question' => 'questions', 'QuestionFollower' => 'question_followers',
      'Reply' => 'replies', 'QuestionLike' => 'question_likes'}
    class_to_table[self.class.to_s]
  end

  def my_var_string
    str = "("
    get_variables.each do |var, value|
      str += "\'#{var.to_s[1..-1]}\', " unless var == :@id
    end
    str = str[0..-3]
    str += ")"
  end

  def my_val_string
    val_arr = get_variables.map { |var, value| value.to_s}[1..-1]
    str = "("

    val_arr.each { |val| str += %Q['#{val}', ]}
    str = str[0..-3]
    str += ")"
  end

  def my_set_string
    val_arr = []
    var_arr = []
    get_variables.each do |var, value|
       val_arr << value.to_s
       var_arr << "#{var} = "[1..-1]
    end

    str = ""
    (1..val_arr.length).each do |i|
      str += %Q[#{var_arr[i]}'#{val_arr[i]}', ]
    end
    str = str[0..-7]
    str
  end

  def save
    if self.id.nil?
      QuestionDatabase.instance.execute(<<-SQL)
        INSERT INTO
          #{my_table + my_var_string}
        VALUES
          #{my_val_string}
      SQL
      self.id = QuestionDatabase.instance.last_insert_row_id
    else
      QuestionDatabase.instance.execute(<<-SQL, self.id)
      UPDATE
        #{my_table}
      SET
        #{my_set_string}
      WHERE
        id = ?
      SQL
    end
  end

end

class User < Saving

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



class Question < Saving

  attr_accessor :id, :title, :body, :author_id

  def initialize(options = {})
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def self.find_by_id(id)
    results = QuestionDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      questions
    WHERE
      id = ?
    SQL

    results.map { |result| Question.new(result)}[0]
  end

  def self.find_by_author_id(author_id)
    results = QuestionDatabase.instance.execute(<<-SQL, author_id)
    SELECT
      *
    FROM
      questions
    WHERE
      author_id = ?
    SQL

    results.map { |result| Question.new(result)}
  end

  def author
    results = QuestionDatabase.instance.execute(<<-SQL, author_id)
    SELECT
      *
    FROM
      users
    WHERE
      id = ?
    SQL

    results.map { |result| User.new(result)}
  end

  def replies
    Reply.find_by_question_id(id)
  end

  def followers
    QuestionFollower.followers_for_question_id(id)
  end

  def self.most_followed(n)
    QuestionFollower.most_followed_questions(n)
  end

  def likers
    QuestionLike.likers_for_question_id(id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(id)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end


end

class QuestionFollower < Saving

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

class Reply < Saving
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

class QuestionLike < Saving

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
    question_likes
    WHERE
    id = ?
    SQL

    results.map { |result| QuestionLike.new(result)}[0]
  end

  def self.likers_for_question_id(question_id)
    results = QuestionDatabase.instance.execute(<<-SQL, question_id)
    SELECT
    users.id, users.fname, users.lname
    FROM
    question_likes JOIN users
    ON user_id = users.id
    WHERE
    question_id = ?
    SQL

    results.map { |result| User.new(result)}
  end

  def self.liked_questions_for_user_id(user_id)
    results = QuestionDatabase.instance.execute(<<-SQL, user_id)
    SELECT
    q.id, q.title, q.body, q.author_id
    FROM
    question_likes JOIN questions q
    ON question_id = q.id
    WHERE
    user_id = ?
    SQL

    results.map { |result| Question.new(result)}
  end

  def self.num_likes_for_question_id(question_id)
    results = QuestionDatabase.instance.execute(<<-SQL, question_id)
    SELECT
    COUNT(*)
    FROM
    question_likes JOIN users
    ON user_id = users.id
    WHERE
    question_id = ?
    SQL

    results[0].values[0]
  end

  def self.most_liked_questions(n)
    results = QuestionDatabase.instance.execute(<<-SQL)
    SELECT
      q.id, q.title, q.body, q.author_id
    FROM
      question_likes JOIN questions q
      ON question_id = q.id
    GROUP BY
      question_id
    ORDER BY
      COUNT(question_id) DESC
    SQL

    results.map { |result| Question.new(result) }[0...n]
  end




end

testUser = User.find_by_id(3)
question1 = Question.find_by_id(1)
reply1 = Reply.find_by_id(1)
testUser2 = User.new({'id' => nil, 'fname' => 'Jack', 'lname' => 'Bower'})
#p testUser2.my_set_string
#p testUser2.get_variables
#
testUser2.save
testUser2.fname = 'TESTING'
testUser2.save
# p testUser2.id
