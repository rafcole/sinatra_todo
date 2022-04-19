require "sinatra"
require "sinatra/reloader" if development?
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

  def erase_lists(list_id = nil)
    if list_id
      session[:lists].delete_if do |list_item_hsh|
        list_item_hsh[:name] == list_id 
        # works with perfect formatting
          # eg /eraselists/Home can't delete a list with the name 'Home'
          # but lowercase works
          # good argument for ID number instead?
      end
    else
      session[:lists] = []
    end
  end

  def unique_list_name?(name)
    session[:lists].all? do |list|
      list[:name] != name
    end
  end

  def valid_list_length?(name)
    (1..100).cover?(name.size) 
  end

  # return error message str if error, otherwise nill
  def error_for_list_name(name)
    puts "unique_list_name?#{name} == #{unique_list_name?(name)}"

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
end


get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error # returns the error message or nil
    puts "hello from line 84"
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

get "/lists/:list_id" do |list_idx|
  @list_idx = list_idx.to_i
  # validate integer
    # helper valid_list_index(usr_str)
  if @list_idx.to_s != list_idx
    session[:error] = "List not found (not an integer"
    redirect "/lists"
  elsif session[:lists][@list_idx].nil?
    session[:error] = "List not found! (index error)"
    redirect "/lists"
  else
    @current_list = session[:lists][@list_idx]
    erb :display_list, layout: :layout
  end
end

# another /lists/* route to redirect non digit inputs?
  # get "/lists/:not_digit_input" do 

#erasing todos - add trashcans, warning dialogues, options for all vs single
get "/eraselists" do
  erase_lists
  redirect "/lists"
end

get "/eraselists/*" do |list_id|
  puts session[:lists].to_s

  puts list_id.to_sym
  erase_lists(list_id)
  redirect "/lists"
end