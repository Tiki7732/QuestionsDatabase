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

    attr_reader :id
    attr_accessor :title, :body, :author_id

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

    def self.find_by_author_id(author_id)
        questions = QuestionDatabase.instance.execute(<<-SQL, author_id)
        SELECT *
        FROM questions
        WHERE author_id = ?
        SQL
        return nil unless questions.length > 0
        questions.each {|question| Question.new(question)}
    end

    def self.most_followed(n)
        QuestionFollow.most_followed_questions(n)
    end

    def self.most_liked(n)
        QuestionLike.most_liked_questions(n)
    end

    def initialize(options)
        @id = options['id']
        @title = options['title']
        @body = options['body']
        @author_id = options['author_id']
    end

    def author
        author = User.find_by_id(self.author_id)
    end

    def replies
        replies = Reply.find_by_question_id(self.id)
    end

    def followers
        users = QuestionFollow.followers_for_question_id(self.id)
    end

    def likers
        likers = QuestionLike.likers_for_question(self.id)
    end

    def num_likes
        num = QuestionLike.num_likes_for_question_id(self.id)
    end

    def save
        if @id
            QuestionDatabase.instance.execute(<<-SQL, @title, @body, @author_id, @id)
            UPDATE questions
            SET title = ?, body = ?, author_id = ?
            WHERE questions.id = ?
            SQL
        else
            QuestionDatabase.instance.execute(<<-SQL, @title, @body, @author_id)
            INSERT INTO questions (title, body, author_id)
            VALUES (?, ?, ?)
            SQL
            @id = QuestionDatabase.instance.last_insert_row_id
        end
        self
    end

end

class User
    attr_reader :id
    attr_accessor :fname, :lname

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

    def self.find_by_name(fname, lname)
        user = QuestionDatabase.instance.execute(<<-SQL, fname, lname)
        SELECT *
        FROM users
        WHERE fname = ? AND lname = ?
        SQL
        return nil unless user.length > 0
        User.new(user.first)
    end

    def initialize(options)
        @id = options['id']
        @fname = options['fname']
        @lname = options['lname']
    end

    def authored_questions
        questions = Question.find_by_author_id(self.id)
    end

    def authored_replies
        replies = Reply.find_by_author_id(self.id)
    end

    def followed_questions
        questions = QuestionFollow.followed_questions_for_user_id(self.id)
    end

    def liked_questions 
        questions = QuestionLike.liked_questions_for_user_id(self.id)
    end

    def average_karma
        likes = QuestionDatabase.instance.execute(<<-SQL, self.id)
        SELECT COUNT(*) AS likes
        FROM question_likes
        JOIN questions ON questions.id = question_likes.question_id
        JOIN users ON questions.author_id = users.id
        WHERE users.id = ?
        SQL
        like_count = likes.first["likes"]
        questions_count = self.authored_questions.length
        average_likes = like_count/questions_count.to_f

    end

    def save
        if @id
            QuestionDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
            UPDATE users
            SET fname = ?, lname = ?
            WHERE users.id = ?
            SQL
        else
            QuestionDatabase.instance.execute(<<-SQL, @fname, @lname)
            INSERT INTO users (fname, lname)
            VALUES (?, ?)
            SQL
            @id = QuestionDatabase.instance.last_insert_row_id
        end
        self
    end
end

class Reply

    attr_reader :id
    attr_accessor :question_id, :parent_reply_id, :author_id, :body

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

    def self.find_by_author_id(author_id)
        reply = QuestionDatabase.instance.execute(<<-SQL, author_id)
        SELECT *
        FROM replies
        WHERE author_id = ?
        SQL
        return nil unless reply.length > 0
        Reply.new(reply.first)
    end

    def self.find_by_question_id(question_id)
        reply = QuestionDatabase.instance.execute(<<-SQL, question_id)
        SELECT *
        FROM replies
        WHERE question_id = ?
        SQL
        return nil unless reply.length > 0
        reply.each {|reply| Reply.new(reply)}
    end

    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @parent_reply_id = options['parent_reply_id']
        @author_id = options['author_id']
        @body = options['body']
    end

    def author
        author = User.find_by_id(self.author_id)
    end

    def question
        question = Question.find_by_id(self.question_id)
    end

    def parent_reply
        reply = Reply.find_by_id(parent_reply_id)
    end

    def child_replies
        child_reply = QuestionDatabase.instance.execute(<<-SQL, self.id)
        SELECT * 
        FROM replies 
        WHERE parent_reply_id = ?
        SQL
        Reply.new(child_reply.first)
    end

    def save
        if @id
            QuestionDatabase.instance.execute(<<-SQL, @question_id, @parent_reply_id, @author_id, @body, @id)
            UPDATE replies
            SET question_id = ?, parent_reply_id = ?, author_id = ?, body = ?
            WHERE replies.id = ?
            SQL
        else
            QuestionDatabase.instance.execute(<<-SQL, @question_id, @parent_reply_id, @author_id, @body)
            INSERT INTO replies (question_id, parent_reply_id, author_id, body)
            VALUES (?, ?, ?, ?)
            SQL
            @id = QuestionDatabase.instance.last_insert_row_id
        end
        self
    end
end

class QuestionFollow

    attr_accessor :id, :user_id, :questoin_id

    def self.followers_for_question_id(question_id)
        users = QuestionDatabase.instance.execute(<<-SQL, question_id)
        SELECT *
        FROM users
        JOIN question_follows ON user_id = users.id
        WHERE question_id = ?
        SQL
        users
    end

    def self.followed_questions_for_user_id(user_id)
        questions = QuestionDatabase.instance.execute(<<-SQL, user_id)
        SELECT *
        FROM questions
        JOIN question_follows ON question_id = questions.id
        WHERE user_id = ?
        SQL
        questions
    end

    def self.most_followed_questions(n)
        followed = QuestionDatabase.instance.execute(<<-SQL, n)
        SELECT questions.*
        FROM questions
        JOIN question_follows ON question_id = questions.id
        GROUP BY questions.id
        ORDER BY COUNT(*)DESC
        LIMIT ?
        SQL
        followed.map{|question| Question.new(question)}
    end
end

class QuestionLike

    attr_accessor :id, :user_id, :question_id

    def self.likers_for_question(question_id)
        likers = QuestionDatabase.instance.execute(<<-SQL, question_id)
        SELECT *
        FROM users
        JOIN question_likes ON users.id = user_id
        WHERE question_likes.question_id = ?
        SQL
        likers.map{|user| User.new(user)}
    end

    def self.num_likes_for_question_id(question_id)
        likes = QuestionDatabase.instance.execute(<<-SQL, question_id)
        SELECT COUNT(*) AS likes
        FROM questions
        JOIN question_likes ON question_likes.question_id = questions.id
        WHERE question_likes.question_id = ?
        SQL
    end

    def self.liked_questions_for_user_id(user_id)
        questions = QuestionDatabase.instance.execute(<<-SQL, user_id)
        SELECT *
        FROM questions
        JOIN question_likes ON question_likes.question_id = questions.id
        WHERE question_likes.user_id = ?
        SQL
        questions.map{|question| Question.new(question)}
    end

    def self.most_liked_questions(n)
        questions = QuestionDatabase.instance.execute(<<-SQL, n)
        SELECT questions.*
        FROM questions
        JOIN question_likes ON question_likes.question_id = questions.id
        GROUP BY questions.id
        ORDER BY COUNT(*) DESC
        LIMIT ?
        SQL
        questions.map{|question| Question.new(question)}
    end
end