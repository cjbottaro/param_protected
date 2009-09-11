class UsersController < ApplicationController
  param_accessible( {:user => [ {:name => [:first, :last]}, :email ]} )
  
  def create; end
  def update; end
    
end
