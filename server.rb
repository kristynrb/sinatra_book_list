# Made using this tutorial: https://x-team.com/blog/how-to-create-a-ruby-api-with-sinatra/

# require gems
require 'sinatra'
require 'sinatra/namespace'
require 'mongoid'

# load Mongoid configuration (DB setup)
Mongoid.load! "mongoid.config"

# creat a Ruby class to create a model
class Book
  include Mongoid::Document

  field :title, type: String
  field :author, type: String
  field :isbn, type: String

  validates :title, presence: true
  validates :author, presence: true
  validates :isbn, presence: true

  index({ title: 'text' })
  index({ isbn: 1 }, {unique: true, name: "isbn_index" })

  scope :title, -> (title){ where(title: /^#{title}/) }
  scope :isbn, -> (isbn) { where(isbn: isbn) }
  scope :author, -> (author) { where(author: author) }
end

# Serializer
class BookSerializer
  def initialize(book)
    @book = book
  end

  def as_json(*)
    data = {
      id:@book.id.to_s,
      title:@book.title,
      author:@book.author,
      isbn:@book.isbn
    }
    data[:errors] = @book.errors if@book.errors.any?
    data
  end
end

# Routes / Endpoints
get '/' do
  'Welcome to Booklist'
end

namespace '/api/v1' do
  # Before
  # get /books
  get '/books/:id' do |id|
    book = Book.where(id: id).first
    halt(404, {message: 'Book not found'}.to_json) unless book
    BookSerializer.new(book).to_json
  end

  before do
    content_type 'application/json'
  end

  get '/books' do
    books = Book.all

    [:title, :isbn, :author].each do |filter|
      books = books.send(filter, params[filter]) if params[filter]
    end

    books.map { |book| BookSerializer.new(book) }.to_json
  end
end
