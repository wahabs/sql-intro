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

module Saveable

  def get_variables
    values = {}
    self.instance_variables.each do |instant_var|
      values[instant_var] = self.instance_variable_get(instant_var)
    end
    values
  end

  def my_table
    class_to_table = {'User' => 'users', 'Question' => 'questions',
                      'QuestionFollower' => 'question_followers',
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
