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

  def valid_list_name()
  
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
  # validate params :list_name
    # redirect to get /lists with session:error
      # hand off display of error to lists.erb with same parameter clearing pattern to 
  new_list = { name: params[:list_name], todos: [] }
  session[:lists] << new_list
  session[:newest_list] = new_list # non-official solution, will need to replace if switching to ids
  session[:success] = "\"#{session[:newest_list][:name]}\" added"

  redirect "/lists"
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