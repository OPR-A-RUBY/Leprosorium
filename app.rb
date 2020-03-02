#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' 
require 'sqlite3'

def init_db											# метод инициализации базы данных		
	@db = SQLite3::Database.new 'leprosorium.db'
	@db.results_as_hash = true
end

before do
	# последующие инициализации базу данных
	init_db
end

configure do
	
	# первая инициализация базы данных
	init_db

	# в базе данных db создать таблицу Posts, если такая не существует
	@db.execute 'CREATE TABLE IF NOT EXISTS "Posts" 
	(
	    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
	    "created_date" DATE,
	    "content" TEXT
	)'
	
end

get '/' do

	# получить массив всех записей как хеши из таблицы Posts (db) 
	@results = @db.execute 'SELECT * FROM Posts ORDER BY id DESC'
	# отсортированный по id в обратном порядке (по-убыванию)

	erb :index
end

get '/new' do
	# вывести представление (/view/new.erb)
	erb  :new 
end

post '/new' do
   	
   	# теперь сонтент из формы (/view/new.erb) будет присвоен переменной content в этом методе 
   	content = params[:content_]

   	# Валидация контента (на пустое значение)
   	if content.length <= 0
   		@error = 'Type post text'  # Сообщение об ошибке
   		return erb :new
   	end

   	# Запись контента в базу данных 
   	@db.execute 'INSERT INTO Posts (content, created_date) VALUES (?, datetime())', [content]
   	
   	# перенаправление на главную страницу
   	redirect to '/'

end