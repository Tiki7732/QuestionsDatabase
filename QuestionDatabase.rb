require 'singleton'
require 'sqlite3'

class QuestionDatabase < SQLite3::Database
    include Singleton

    def initialize  
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class Question

    attr_accessor :id, :title, :body, :author_id

    def self.all
        data = QuestionDatabase.instance.execute("SELECT * FROM questions")
        data.map{|question| Question.new(question)}
    end

    def self.find_by_id(id)
        question = QuestionDatabase.instance.execute(<<-SQL, id)
        SELECT *
        FROM questions
        WHERE id = ?
        SQL
        return nil unless question.length > 0
        Question.new(question.first)
    end

    def self.find_by_title(title)
        question = QuestionDatabase.instance.execute(<<-SQL, title)
        SELECT *
        FROM questions
        WHERE title = ?
        SQL
        return nil unless question.length > 0
        Question.new(question.first)
    end

    def initialize(options)
        @id = options['id']
        @title = options['title']
        @body = options['body']
        @author_id = options['author_id']
    end
end

class User
    attr_accessor :id, :fname, :lname

    def self.all
        data = QuestionDatabase.instance.execute("SELECT * FROM users")
        data.map{|user| User.new(user)}
    end

    def self.find_by_id(id)
        user = QuestionDatabase.instance.execute(<<-SQL, id)
        SELECT *
        FROM users
        WHERE id = ?
        SQL
        return nil unless user.length > 0
        User.new(user.first)
    end

    def initialize(options)
        @id = options['id']
        @fname = options['fname']
        @lname = options['lname']
    end
end

class Reply

    attr_accessor :id, :question_id, :parent_reply_id, :author_id, :body

    def self.all
        data = QuestionDatabase.instance.execute("SELECT * FROM replies")
        data.map{|reply| Reply.new(reply)}
    end

    def self.find_by_id(id)
        reply = QuestionDatabase.instance.execute(<<-SQL, id)
        SELECT *
        FROM replies
        WHERE id = ?
        SQL
        return nil unless reply.length > 0
        Reply.new(reply.first)
    end

    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @parent_reply_id = options['parent_reply_id']
        @author_id = options['author_id']
        @body = options['body']
    end
end