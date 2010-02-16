class InheritedUsersController < UsersController
  param_accessible :user => :password
  param_protected :user => :name
end
