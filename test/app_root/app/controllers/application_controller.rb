class ApplicationController < ActionController::Base
  before_filter :render_nothing
  
private

  def render_nothing
    render :nothing => true
  end
  
end
