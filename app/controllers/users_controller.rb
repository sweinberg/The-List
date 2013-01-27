class UsersController < ApplicationController

  skip_before_filter :require_login, :except => [:new,:profile]

  #for adding a new user
	def new
    respond_to do |format|
      @user = User.new
      format.html # new.html.erb
      format.json { render json: @user }
    end
	end

	def create
		email = params[:user][:email]
		karma = params[:user][:karma]
		name = params[:user][:name]

		generated_token = SecureRandom.urlsafe_base64

    @user = User.find_or_initialize_by_auth_token(:auth_token => generated_token, :karma => karma)

    unless [email, karma, name].any?{|f| f.blank? }
      if User.find_by_email(params[:user][:email])
        User.first.send_gift(email, karma, '', current_user.username, 1, name)
        redirect_to root_url, :notice => "Your karma has been gifted."
      elsif @user.save
        User.first.send_gift(email, karma, generated_token, current_user.username, 0, name)
        redirect_to root_url, :notice => "Your invite has been sent."
      end
    else
      redirect_to request.env["HTTP_REFERER"], :notice => "Ooops. You should check your form again."
    end

    @user.update_attributes({
      :karma => @user.karma + params[:karma].to_i
    })
	end

	def user
    @user = User.find_by_username(params[:username])

    @posts = Post
    .where(:user_id => User.find_by_username(params[:username]).id)
    .joins("LEFT JOIN votes ON posts.id = votes.post_id")
    .select("posts.id," +
      "sum(if(direction = 0, value, if(direction is null, 0, -value))) as score," +
      "posts.created_at," +
      "url," +
      "title," +
      "posts.user_id," +
      "comment_count")
    .group("posts.id")
    .order("log10(abs(sum(if(direction = 0, value, if(direction is null, 0, -value)))) + 1) * sign(sum(if(direction = 0, value, if(direction is null, 0, -value)))) + (unix_timestamp(posts.created_at) / 300000) DESC")
  end

  def update
  	@auth_token = params[:auth_token]
  	@password = params[:password]

    @user = User.find_by_auth_token(@auth_token)

    if params.include?(:user)

      email = params[:user][:email]
      username = params[:user][:username]
      password = params[:user][:password]
      password_conf = params[:user][:password_confirmation]

      unless [email, username, password, password_conf].any?{|f| f.blank? }
      	password_salt = BCrypt::Engine.generate_salt

    	  if User.find_by_auth_token(params[:user][:auth_token]).update_attributes({
  	  	  	:email => params[:user][:email],
  	  	  	:username => params[:user][:username],
  	  	  	:password_hash => BCrypt::Engine.hash_secret(params[:user][:password], password_salt),
  	  	  	:password_salt => password_salt
  	  	  })

    	    cookies.delete(:auth_token)

        	redirect_to log_in_path, :notice => "You account has been created. Sign in with your email and password."
        end
      else
        redirect_to request.env["HTTP_REFERER"], :notice => "Ooops. You should check your form again."
      end
    else
      render :update
    end
  end
end
