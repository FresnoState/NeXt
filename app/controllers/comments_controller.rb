class CommentsController < ApplicationController

  before_action :find_comment, only: [:edit, :update, :destroy]

  before_action only: [:edit, :update, :destroy] do
    unless @comment.is_editable_by? current_user
      require_login_status
      redirect_to :new_auth_local
    end
  end

  def new
    @comment = Comment.new
    @comment.parent_id = params[:parent_id]
    @comment.commentable = @comment.root.commentable
    set_return_to
    render :layout => false
  end

  def create

    path = params[:return_to]

    unless context.user
      raise Application::Error.new "You must be logged in to comment",
                                     redirect_to: [
                                         auth_oauth2_launch_url(:shibboleth),
                                         flash: { return_to: path }
                                     ]
    end
    begin
      context.user.comments.create!(params[:comment].permit(:parent_id, :commentable_id, :commentable_type, :body, :commit))
      change_user_points(params[:commentable_type], 2)      
      flash[:page_alert] = "Thanks for commenting!"
      flash[:page_alert_type] = 'success'
    rescue Exception => e
      flash[:page_alert] = e.message
      flash[:page_alert_type] = 'warning'
    end
    redirect_to params[:return_to] 
  end

  def edit
    set_return_to
    render :layout => false
  end

  def update
    path = params[:return_to]
    begin
      @comment.edited = true
      @comment.update!(params[:comment].permit(:body,:commit))    
      flash[:page_alert] = "Thanks for commenting!"
      flash[:page_alert_type] = 'success'
    rescue Exception => e
      flash[:page_alert] = e.message
      flash[:page_alert_type] = 'warning'
    end
    redirect_to params[:return_to] 
  end

  def destroy
    change_user_points(@comment.commentable_type, -2)
    @comment.destroy
    flash[:page_alert] = "The comment was deleted successfully."
    flash[:page_alert_type] = 'success'
    redirect_to params[:return_to] 
  end

  private
  def find_comment
    @comment = Comment.find_by(:id => params[:id])
  end

  def set_return_to
    case @comment.commentable_type
    when "Idea"
      @comment.return_to = idea_path(@comment.commentable)
    when "Project"
      @comment.return_to = project_path(@comment.commentable)
    end
  end

  def change_user_points(type,points)
    case type
    when "Idea"
      current_user.alter_points :ideas, points
    when "Project"
      current_user.alter_points :projects, points
    end 
  end

end
