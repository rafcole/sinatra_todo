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

  def unique_list_name?(list_name)
    return false if session[:lists].any? do |list|
      list[:name] == list_name
    end
  end

  def valid_list_name?(list_name)
    (1..100).cover?(list_name.size) 
  end
end

before do 
  session[:lists] ||= []
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

  if valid_list_name?(list_name) == false
    session[:error] = 'List names must be between 1 and 100 characters'
    erb :new_list, layout: :layout
  elsif unique_list_name?(list_name) == false
    session[:error] = "List not added - a list named \"#{list_name}\" already exists"

    erb :new_list, layout: :layout 
    # repetition of pattern, can pages be rendered from helper?
  else
    new_list = { name: list_name, todos: [] }
    session[:lists] << new_list
    session[:newest_list] = new_list # non-official solution, will need to replace if switching to ids
    session[:success] = "\"#{session[:newest_list][:name]}\" added"

    redirect "/lists"
  end
end

get "/lists/new" do
  erb :new_list, layout: :layout
end


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