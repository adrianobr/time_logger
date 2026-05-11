class TimeLoggersController < ApplicationController
  before_action :find_time_logger, :only => [:resume, :suspend, :stop, :delete]
  after_action :apply_status_transition, only: :start,
               if: proc { Setting.plugin_time_logger['status_transitions'].present? }

  def index
    if User.current.nil?
      @user_time_loggers = nil
      @time_loggers = TimeLogger.all
    else
      @user_time_loggers = TimeLogger.where(user_id: User.current.id)
      @time_loggers = TimeLogger.where('user_id != ?', User.current.id)
    end
  end

  def start
    issue_id = params[:issue_id].presence

    if issue_id.nil?
      respond_to do |format|
        format.html do
          flash[:error] = l(:start_time_logger_error)
          redirect_back_or_default issues_path
        end
        format.js { head :bad_request }
      end
      return
    end

    if TimeLogger.exists?(:user_id => User.current.id)
      respond_to do |format|
        format.html do
          flash[:warning] = l(:time_logger_already_running_error)
          redirect_to issue_path(issue_id)
        end
        format.js { head :bad_request }
      end
      return
    end

    @time_logger = TimeLogger.new(:issue_id => issue_id)
    @time_logger.started_on = Time.current

    respond_to do |format|
      if @time_logger.save
        format.js { render :partial => 'time_loggers/start' }
        format.html { redirect_to issue_path(@time_logger.issue_id) }
      else
        format.js { head :internal_server_error }
        format.html do
          flash[:error] = l(:start_time_logger_error)
          redirect_to issue_path(issue_id)
        end
      end
    end
  end

  def resume
    issue_id = @time_logger&.issue_id

    if @time_logger.try(:paused)
      @time_logger.started_on = Time.current
      @time_logger.paused = false

      respond_to do |format|
        if @time_logger.save
          format.js { render partial: 'time_loggers/resume' }
          format.html do
            flash[:notice] = l(:time_logger_resumed_notice)
            redirect_to issue_path(issue_id)
          end
        else
          format.js { head :internal_server_error }
          format.html do
            flash[:error] = l(:resume_time_logger_error)
            redirect_to issue_path(issue_id)
          end
        end
      end
    else
      respond_to do |format|
        format.html do
          flash[:warning] = l(:time_logger_resume_invalid_notice)
          redirect_to(issue_id ? issue_path(issue_id) : issues_path)
        end
        format.js { head :bad_request }
      end
    end
  end

  def suspend
    issue_id = @time_logger&.issue_id

    if @time_logger.try(:paused) == false
      @time_logger.time_spent = @time_logger.seconds_spent
      @time_logger.paused = true

      respond_to do |format|
        if @time_logger.save
          format.js { render partial: 'time_loggers/suspend' }
          format.html do
            flash[:notice] = l(:time_logger_suspended_notice)
            redirect_to issue_path(issue_id)
          end
        else
          format.js { head :internal_server_error }
          format.html do
            flash[:error] = l(:suspend_time_logger_error)
            redirect_to issue_path(issue_id)
          end
        end
      end
    else
      respond_to do |format|
        format.html do
          flash[:warning] = l(:time_logger_suspend_invalid_notice)
          redirect_to(issue_id ? issue_path(issue_id) : issues_path)
        end
        format.js { head :bad_request }
      end
    end
  end

  def stop
    issue_id = @time_logger.issue_id
    hours = @time_logger.hours_spent
    @time_logger.destroy

    redirect_to_prefilled_issue_time_entry(issue_id, hours)
  end

  def delete
    @time_logger.destroy
    flash[:notice] = l(:time_logger_delete_success)
    respond_to do |format|
      format.html {redirect_to time_logger_index_path}
    end
  end

  private

  def apply_status_transition
    issue = @time_logger.issue
    new_status_id = Setting.plugin_time_logger['status_transitions'][issue.status_id.to_s]
    new_status = IssueStatus.find_by_id(new_status_id)
    if issue.new_statuses_allowed_to(User.current).include?(new_status)
      issue.init_journal(User.current, l(:time_logger_label_transition_journal))
      issue.status_id = new_status_id
      issue.save
    end
  end

  def find_time_logger
    @time_logger = TimeLogger.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html do
        flash[:error] = l(:no_time_logger)
        redirect_back_or_default(request.referer || issues_path)
      end
      format.js { head :not_found }
    end
    throw :abort
  end

  # GET /issues/:issue_id/time_entries/new?time_entry[hours]=…
  def redirect_to_prefilled_issue_time_entry(issue_id, hours)
    h = hours.to_f
    q = Rack::Utils.build_nested_query('time_entry' => { 'hours' => h })
    r = Redmine::Utils.relative_url_root.to_s.sub(%r{\A/}, '').sub(%r{/\z}, '')
    path = r.present? ? "/#{r}/issues/#{issue_id}/time_entries/new" : "/issues/#{issue_id}/time_entries/new"
    redirect_to "#{path}?#{q}"
  end
end
