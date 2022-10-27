require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def remaining_todo_ct(list)
    list[:todos].select {|todo| todo[:complete] == false}.size
  end

  def list_completed?(list)
    list[:todos].all? {|todo| todo[:complete] == true} && list[:todos].size != 0
  end

  def list_class(list)
    "complete" if list_completed?(list)
  end

  def todo_ct(list)
    list[:todos].size
  end

  def sort_lists(lists)
    arr = []
    lists.each_with_index do |list, index|
      if list_completed?(list) 
        arr << [list, index, 2]
      else
        arr << [list, index, 1]
      end
    end
    arr.sort_by! { |element| element[2]}
    arr.each {|element| yield(element[0], element[1]) }
  end

  def sort_todos(todos)
    arr = []
    todos.each_with_index do |todo, index|
      if todo[:complete]
        arr << [todo, index, 2]
      else
        arr << [todo, index, 1]
      end
    end
    arr.sort_by! { |element| element[2] }
    arr.each {|element| yield(element[0], element[1]) }
  end

end


before do
  session[:lists] ||= []
  @lists = session[:lists]
end

get '/' do
  redirect '/lists'
end

get '/lists' do
  erb :lists
end

get '/lists/new' do
  erb :new_list
end

# create a new list
post '/lists' do
  list_name = params[:list_name].strip

  error = list_validation_error(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    @lists << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

get '/lists/:list_index' do
  @list_index = params[:list_index].to_i
  @list = @lists[@list_index]
  erb :list
end

get '/lists/:list_index/edit' do
  @list_index = params[:list_index].to_i
  @list = @lists[@list_index]
  erb :edit_list
end

# edit list name
post '/lists/:list_index' do
  list_name = params[:list_name].strip
  @list_index = params[:list_index].to_i
  @list = @lists[@list_index]

  error = list_validation_error(list_name)
  if error
    session[:error] = error
    erb :edit_list
  else
    @list[:name] = list_name
    session[:success] = 'The list name has been updated.'
    redirect "/lists/#{@list_index}"
  end
end

# delete list
post '/lists/:list_index/delete' do
  list_index = params[:list_index].to_i
  @lists.delete_at(list_index)
  session[:success] = 'The list has been deleted.'
  redirect '/lists'
end

# add todos to a list
post '/lists/:list_index/todos' do
  @list_index = params[:list_index].to_i
  @list = @lists[@list_index]
  todo = params[:todo].strip

  error = todo_validation_error(todo)
  if error
    session[:error] = error
    erb :list
  else
    @list[:todos] << {name: todo, complete: false}
    session[:success] = 'The todo has been added.'
    redirect "/lists/#{@list_index}"
  end
end

# delete todo from a list
post '/lists/:list_index/:todo_index/delete' do
  @list_index = params[:list_index].to_i
  @list = @lists[@list_index]

  todo_index = params[:todo_index].to_i
  @list[:todos].delete_at(todo_index)
  session[:success] = 'The todo has been deleted.'
  redirect "/lists/#{@list_index}"
end

# check todo status
post '/lists/:list_index/todos/:todo_index' do
  @list_index = params[:list_index].to_i
  @list = @lists[@list_index]

  todo_index = params[:todo_index].to_i
  is_completed = (params[:complete] == 'true')
  @list[:todos][todo_index][:complete] = is_completed
  session[:success] = 'The completion status has been updated.'
  redirect "/lists/#{@list_index}" 
end

# check all todo status
post '/lists/:list_index/complete_all' do
  @list_index = params[:list_index].to_i
  @list = @lists[@list_index]

  @list[:todos].each do |todo|
    todo[:complete] = true
  end
  
  session[:success] = 'All task has been completed'
  redirect "/lists/#{@list_index}" 
end

def list_validation_error(name)
  if !(1..100).cover?(name.size)
    "List name must be between 1 and 100 characters!"
  elsif @lists.any? { |list| list[:name] == name }
    "This list already exist"
  end
end

def todo_validation_error(name)
  if !(1..100).cover?(name.size)
    "Todo name must be between 1 and 100 characters!"
  elsif @list[:todos].any? { |todo| todo[:name] == name }
    "This todo already exist"
  end
end