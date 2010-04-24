class UsersController < ApplicationController
  param_accessible( {:user => [ {:name => [:first, :last], /\A\d+\z/ => :ok}, :email ]} )
  
  def create; end
  def update; end
    
end
