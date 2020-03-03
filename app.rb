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

	# в базе данных db создать таблицу Comments, если такая не существует
	@db.execute 'CREATE TABLE IF NOT EXISTS "Comments" 
	(
	    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
	    "created_date" DATE,
	    "content" TEXT,
	    "post_id" INTEGER
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
   	
   	# теперь имя автора из (/view/new.erb) будет присвоен переменной autor в этом методе
   	@autor = params[:autor_]

   	# Валидация имени автора (на пустое значение)
   	if @autor.length <= 0
   		@error = 'Type Your name'  # Сообщение об ошибке при вводе поста
   		return erb :new
   	end

   	# теперь контент из формы (/view/new.erb) будет присвоен переменной content в этом методе 
   	@content = params[:content_]

   	# Валидация контента (на пустое значение)
   	if @content.length <= 0
   		@error = 'Type post text'  # Сообщение об ошибке при вводе поста
   		return erb :new
   	end
   	
   	
   	# Запись контента в базу данных 
   	@db.execute 'INSERT INTO Posts (content, created_date) VALUES (?, datetime())', [@content]
   	
   	# перенаправление на главную страницу
   	redirect to '/'

end

# Вывод информации о посте
get '/details/:post_id' do

	# Получаем переменную из url
	post_id = params[:post_id]

	# получить results - массив всех записей как хеши из таблицы Posts (db) у которых ... 
	results = @db.execute 'SELECT * FROM Posts WHERE id = ?', [post_id]
	# ... id равен post_id (это будет одна запись. Её индекс в массиве будет всегда 0 )

	# получаем массива ХЕШ выбранной записи (глобальный, для использования в details.erb)
	@row = results[0]

	# Вывод всех коментариев к данному посту
	# Выбрать все коментарии (ХЕШИ) у которых post_id = нашему посту. Сортировать по id.
	@comments = @db.execute 'SELECT * FROM Comments WHERE post_id = ? ORDER BY id', [post_id]
	# Полученная глобальная переменная - есть массив хешей. 
	# Будем его использовать в представлении details.erb

 	erb :details

end

# Обработчик post-запроса /details/...
# Бараузер отправляет параметры на сервер, а мы здесь принимаем их и обработываем
post '/details/:post_id' do

	# Получаем переменную из url
	post_id = params[:post_id]

	# теперь контент из формы (/view/details.erb) будет присвоен переменной content  
   	content = params[:content_]	

   	# Валидация контента (на пустое значение)
   	if content.length <= 0
   		@error = 'Type comment text'  # Сообщение об ошибке при вводе комментария
   		results = @db.execute 'SELECT * FROM Posts WHERE id = ?', [post_id]
   		@row = results[0]
   		@comments = @db.execute 'SELECT * FROM Comments WHERE post_id = ? ORDER BY id', [post_id]
   		return erb :details
   	end

   	# Запись контента в базу данных 
   	@db.execute 'INSERT INTO Comments 
	   		(
	   			content, 
	   			created_date, 
	   			post_id
	   		) 
   		VALUES 
	   		(
	   			?, 
	   			datetime(), 
	   			?
	   		)', 
	   	[content, post_id]

   	# перенаправление на страницу поста
   	redirect to('/details/' + post_id)
   
end

