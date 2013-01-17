class Gift < ActiveRecord::Base
  attr_accessible :email, :karma, :gift, :username, :password, :password_salt

  set_table_name "users"

  validates_presence_of :email
  validates :karma, :numericality => { :only_integer => true }

	def generate_token(column)
	  begin
	    self[column] = SecureRandom.urlsafe_base64
	  end while User.exists?(column => self[column])
	end
	
	def send_gift(email)

	end
end