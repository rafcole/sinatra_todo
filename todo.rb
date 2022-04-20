require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"



configure do
  enable :sessions
  set :session_secret, 'secret' # development only gimmick, not for prod
  # auto generates on every restart of sinatra, which will eliminate the session
end

helpers do 
  def list_items(item)
    "<li><%=#{item}%></li>"
  end

  def unique_list_name?(name)
    session[:lists].all? do |list|
      list[:name] != name
    end
  end

  def unique_todo_desc?(list, todo_desc)
    list[:todos].all? do |todo_hsh|
      todo_hsh[:desc] != todo_desc
    end
  end

  def valid_desc_length?(todo)
    # No upper limit
    (1..500).cover? todo.size
  end

  def valid_list_length?(name)
    (1..100).cover?(name.size) 
  end

  def error_for_todo_desc(list, todo_desc)
    if valid_desc_length?(todo_desc) == false
      'Todo not added - minimum length not met'
    elsif unique_todo_desc?(list, todo_desc) == false # assumed repeat
      "Todo not added - \"#{todo_desc}\" already exists"
    else
      nil
    end
  end

  # return error message str if error, otherwise nill
  def error_for_list_name(name)
    if valid_list_length?(name) == false
      'List names must be between 1 and 100 characters'
    elsif unique_list_name?(name) == false
      "List not added - a list named \"#{name}\" already exists"
    else
      nil
    end
  end
end

before do 
  session[:lists] ||= [
                       name: "Chores",
                       todos: [ 
                         { desc: "Sweep",
                           complete: false },
                         { desc: "Vacuum",
                           complete: false },
                         { desc: "Water plants",
                           complete: false }
                       ]

  ]
  # Why not @lists = session[:lists] up here?
  @lists = session[:lists]
end


get "/" do
  redirect "/lists"
end

get "/lists" do
  #@lists = session[:lists]
  erb :lists, layout: :layout
end

post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error # returns the error message or nil
    session[:error] = error
    erb :new_list, layout: :layout
  else # the erb call from 'if' above doesn't stop the rest from executing, need if/else for exclusion
    new_list = { name: list_name, todos: [] } # assumed arr of str?
    session[:lists] << new_list
    session[:newest_list] = new_list # non-official solution, will need to replace if switching to ids
    session[:success] = "\"#{session[:newest_list][:name]}\" added"

    redirect "/lists"
  end
end

get "/lists/new" do
  
  erb :new_list, layout: :layout
end

# display an individual list
get "/lists/:list_id" do |list_id|
  # relative lists in the view template start from '/lists' not 'lists/:list_id'

  @list_id = list_id.to_i
  # validate integer
    # helper valid_list_index(usr_str)
  if @list_id.to_s != list_id
    session[:error] = "List not found (not an integer"
    redirect "/lists"
  elsif session[:lists][@list_id].nil?
    session[:error] = "List not found! (index error)"
    redirect "/lists"
  else
    @current_list = session[:lists][@list_id]
    erb :display_list, layout: :layout
  end
end

# edit an individual list
get "/lists/:list_id/edit" do |list_id|
  @list_id = list_id
  @current_list = session[:lists][list_id.to_i]

  erb :edit_list, layout: :layout
end

# form submission to rename a list
# so much overlap with post "/list", what can be extracted?
post "/lists/:list_id" do |list_id|
  @current_list = session[:lists][list_id.to_i]
  new_list_name = params[:new_list_name].strip

  edit_route = "/lists/#{list_id}/edit".to_sym

  error = error_for_list_name(new_list_name)
  if error 
    session[:invalid_name] = new_list_name.empty?  ? "(must_include_letters)" : new_list_name

    session[:error] = error
    #redirect edit_route # using redirect resets params
    erb :edit_list, layout: :layout
  else 
    # success message
    session[:success] = "\"#{@current_list[:name]}\" has been renamed \"#{new_list_name}\""

    # actually changing the name
    @current_list[:name] = new_list_name

    redirect "/lists/#{list_id}"
  end
end

# delete a list
post "/lists/:list_id/delete" do |list_id|
  session[:success] = "#{session[:lists][list_id.to_i][:name]} succesfully deleted"
  session[:lists].delete_at(list_id.to_i)

  redirect "/lists"
  # does this redirect make sense?
    # with @lists bumped from '/list route' into 'before' we can render /lists here
  erb :lists, layout: :layout
end


# add a todo to a list
post "/lists/:list_id/todos" do |list_id|
  @list_id = list_id.to_i
  @current_list = session[:lists][@list_id]
  new_todo_desc = params[:todo].strip

  # returns error or nil
  error = error_for_todo_desc(@current_list, new_todo_desc)

  if error
    session[:error] = error
    @place_holder = new_todo_desc
  else
    new_todo = { desc: new_todo_desc, complete: false }
    @current_list[:todos] << new_todo
  
    session[:success] = 'Todo added'
  end
   
  erb :display_list, layout: :layout
end

# delete a todo
post "/lists/:list_id/todos/:todo_id/delete" do |list_id, todo_id|
  @list_id = list_id.to_i
  @current_list = session[:lists][@list_id] # {name:'monday', todos:[{todo},{todo}]}
  current_todo = @current_list[:todos][todo_id.to_i] 

  # Set a success message
  session[:success] = "\"#{current_todo[:desc]}\" has been deleted"
  # Delete the todo from the array of todo hashes
  @current_list[:todos].delete_at(todo_id.to_i)

  # Render specific list page
  erb :display_list, layout: :layout
end



get "/eraselists" do
  session[:lists] = []
  redirect "/lists"
end