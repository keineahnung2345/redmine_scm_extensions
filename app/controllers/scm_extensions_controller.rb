# SCM Extensions plugin for Redmine
# Copyright (C) 2010 Arnaud MARTEL
# Copyright (C) 2021 keineahnung2345 <mimifasosofamire1123@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
require 'tmpdir'
require 'fileutils'

class ScmExtensionsController < ApplicationController
  unloadable

  layout 'base'
  before_action :find_project, :except => [:show, :download]
  before_action :find_repository, :only => [:show, :download]
  before_action :authorize, :except => [:show, :download]

  helper :attachments
  include AttachmentsHelper
  include SCMExtensionsZip

  def upload
    path_root = @repository.identifier.blank? ? "root" : @repository.identifier
    path = ""
    path << path_root
    path << "/#{params[:path]}" if (params[:path] && !params[:path].empty?)
    @scm_extensions = ScmExtensionsWrite.new(:path => path, :project => @project, :repository => @repository)
    @is_upload_folder = false

    if !request.get? && !request.xhr?
      @scm_extensions.path = params[:scm_extensions][:path]
      @scm_extensions.comments = params[:scm_extensions][:comments]
      @scm_extensions.recipients = params[:watchers]
      reg = Regexp.new("^#{path_root}")
      path = params[:scm_extensions][:path].sub(reg,'').sub(/^\//,'')
      attached = []
      if params[:attachments] && params[:attachments].is_a?(ActionController::Parameters)
        svnpath = path.empty? ? "/" : path
        if @repository.scm.respond_to?('scm_extensions_upload')
          ret = @repository.scm.scm_extensions_upload(@repository, svnpath, params[:attachments], params[:scm_extensions][:comments], nil)
          case ret
          when 0
            flash[:notice] = l(:notice_scm_extensions_upload_success)
            @scm_extensions.deliver(params[:attachments]) if @scm_extensions.recipients
          when 1
            flash[:error] = l(:error_scm_extensions_upload_failed)
          when 2
            flash[:error] = l(:error_scm_extensions_no_path_head)
          end
        end

      end
      path = format_path(path)
      if @repository.identifier.blank?
        redirect_to :controller => 'repositories', :action => 'show', :id => @project, :path => path
      else
        redirect_to :controller => 'repositories', :action => 'show', :id => @project, :repository_id => @repository.identifier, :path => path
      end
      return
    end
  end

  def upload_folder
    path_root = @repository.identifier.blank? ? "root" : @repository.identifier
    path = ""
    path << path_root
    path << "/#{params[:path]}" if (params[:path] && !params[:path].empty?)
    @scm_extensions = ScmExtensionsWrite.new(:path => path, :project => @project, :repository => @repository)
    @is_upload_folder = true

    if !request.get? && !request.xhr?
      @scm_extensions.path = params[:scm_extensions][:path]
      @scm_extensions.comments = params[:scm_extensions][:comments]
      @scm_extensions.recipients = params[:watchers]
      reg = Regexp.new("^#{path_root}")
      path = params[:scm_extensions][:path].sub(reg,'').sub(/^\//,'')
      attached = []
      if params[:attachments] && params[:attachments].is_a?(ActionController::Parameters)
        svnpath = path.empty? ? "/" : path
        if @repository.scm.respond_to?('scm_extensions_upload_folder')
          ret = @repository.scm.scm_extensions_upload_folder(@repository, svnpath, params[:attachments], params[:scm_extensions][:comments], nil, params[:keep_outermost], params[:overwrite])
          case ret
          when 0
            flash[:notice] = l(:notice_scm_extensions_upload_success)
            @scm_extensions.deliver(params[:attachments]) if @scm_extensions.recipients
          when 1
            flash[:error] = l(:error_scm_extensions_upload_failed)
          when 2
            flash[:error] = l(:error_scm_extensions_no_path_head)
          when 3
            flash[:error] = l(:error_scm_extensions_compressed_file_unsupported_format)
          end
        end

      end
      path = format_path(path)
      if @repository.identifier.blank?
        redirect_to :controller => 'repositories', :action => 'show', :id => @project, :path => path
      else
        redirect_to :controller => 'repositories', :action => 'show', :id => @project, :repository_id => @repository.identifier, :path => path
      end
      return
    end
  end

  def delete
    path = params[:path]
    parent = path
    svnpath = path.empty? ? "/" : path

    if @repository.scm.respond_to?('scm_extensions_delete')
      ret = @repository.scm.scm_extensions_delete(@repository, svnpath, "deleted #{path}", nil)
      case ret
      when 0
        parent = File.dirname(svnpath).sub(/^\//,'')
        parent = "" if parent == "."
        flash[:notice] = l(:notice_scm_extensions_delete_success)
      when 1
        flash[:error] = l(:error_scm_extensions_delete_failed)
      end
    end
    path = format_path(parent)
    if @repository.identifier.blank?
      redirect_to :controller => 'repositories', :action => 'show', :id => @project, :path => path
    else
      redirect_to :controller => 'repositories', :action => 'show', :id => @project, :repository_id => @repository.identifier, :path => path
    end
    return
  end

  def mkdir
    path_root = @repository.identifier.blank? ? "root" : @repository.identifier
    path = ""
    path << path_root
    path << "/#{params[:path]}" if (params[:path] && !params[:path].empty?)
    @scm_extensions = ScmExtensionsWrite.new(:path => path, :project => @project)

    if !request.get? && !request.xhr?
      path = params[:scm_extensions][:path].sub(/^#{path_root}/,'').sub(/^\//,'')
      foldername = params[:scm_extensions][:new_folder]
      svnpath = path.empty? ? "/" : path
      
      if @repository.scm.respond_to?('scm_extensions_mkdir')
        ret = @repository.scm.scm_extensions_mkdir(@repository, File.join(svnpath, foldername), params[:scm_extensions][:comments], nil)
        case ret
        when 0
          flash[:notice] = l(:notice_scm_extensions_mkdir_success)
        when 1
          flash[:error] = l(:error_scm_extensions_mkdir_failed)
        end
      end
      path = format_path(path)
      if @repository.identifier.blank?
        redirect_to :controller => 'repositories', :action => 'show', :id => @project, :path => path
      else
        redirect_to :controller => 'repositories', :action => 'show', :id => @project, :repository_id => @repository.identifier, :path => path
      end
      return
    end
  end

  def show
    return if !User.current.allowed_to?(:browse_repository, @project)
    @show_cb = params[:show_cb] if params[:show_cb] && !(params[:show_cb] =~ (/(false|f|no|n|0)$/i))
    @show_rev = params[:show_rev] if params[:show_rev] && !(params[:show_rev] =~ (/(false|f|no|n|0)$/i))
    @link_details = params[:link_details] if params[:link_details] && !(params[:link_details] =~ (/(false|f|no|n|0)$/i))
    @entries = @repository.entries(@path, @rev)
    if request.xhr?
      @entries ? render(:partial => 'scm_extensions/dir_list_content') : render(:nothing => true)
    end
  end

  def download
    return if !User.current.allowed_to?(:browse_repository, @project)
    @entry = @repository.entry(@path, @rev)
    (show_error_not_found; return) unless @entry

    if @entry.is_dir?
      if @repository.scm.respond_to?('scm_extensions_download')
        zip = SCMExtensionsZip::Zip.new
        zip.add_folder(@repository, @path, @rev, @path)
        send_file(zip.finish,
          filename: "#{@entry.name ? @entry.name : @repository.identifier}-#{DateTime.current.strftime('%y%m%d%H%M%S')}.zip",
          type: 'application/zip',
          disposition: 'attachment')
        zip.close if zip
      end
    else
      if @repository.is_a?(Repository::Filesystem)
        data_to_send = File.new(File.join(@repository.scm.url, @path))
        (show_error_not_found; return) unless File.exists?(data_to_send.path)
        send_file File.expand_path(data_to_send.path), :filename => @path.split('/').last, :stream => true
      else
        @content = @repository.cat(@path, @rev)
        (show_error_not_found; return) unless @content
        # Force the download
        send_data @content, :filename => @path.split('/').last, :disposition => "inline", :type => Redmine::MimeType.of(@path.split('/').last)
      end
    end
  end

  def notify
    path_root = @repository.identifier.blank? ? "root" : @repository.identifier
    path = ""
    path << path_root
    path << "/#{params[:path]}" if (params[:path] && !params[:path].empty?)
    @scm_extensions = ScmExtensionsWrite.new(:path => path, :project => @project, :repository => @repository)
    @show_cb = true

    @rev = nil
    @show_rev = nil
    @link_details = nil
    #need @entries, @rev, @project
    spath = ""
    spath = params[:path] if (params[:path] && !params[:path].empty?)
    @entry = @repository.entry(spath, @rev)
    isdir = (@entry.kind == "dir")
    @entries = isdir ? @repository.entries(spath,@rev) : [@entry]

    if !request.get? && !request.xhr?
      @scm_extensions.path = params[:scm_extensions][:path]
      @scm_extensions.comments = params[:scm_extensions][:comments]
      @scm_extensions.recipients = params[:watchers]
      reg = Regexp.new("^#{path_root}")
      path = params[:scm_extensions][:path].sub(reg,'').sub(/^\//,'')
      @entry = @repository.entry(path, @rev)
      isdir = (@entry.kind == "dir")
      @entries = isdir ? @repository.entries(path,@rev) : [@entry]
      attached = []
      svnpath = path.empty? ? "/" : path
      selectedfiles = []
      if !isdir
        # if the notify button on file's page is clicked, there is no need to select files
        selectedfiles = [File.basename(path)]
      elsif params[:selectedfiles]
        reg2 = Regexp.new("^#{path}")
        params[:selectedfiles].each do |entrypath|
          selectedfiles << (isdir ? entrypath.sub(reg2,'').sub(/^\//,'') : File.basename(entrypath))
        end
      end

      @scm_extensions.notify(selectedfiles) 
      flash[:notice] = l(:notice_scm_extensions_email_success) if @scm_extensions.recipients
      action = (isdir ? 'show' : 'entry')
      path = format_path(path)
      if @repository.identifier.blank?
        redirect_to :controller => 'repositories', :action => action, :id => @project, :path => path
      else
        redirect_to :controller => 'repositories', :action => action, :id => @project, :repository_id => @repository.identifier, :path => path
      end
      return
    end
  end

  def rename
    path_root = @repository.identifier.blank? ? "root" : @repository.identifier
    path = ""
    path << path_root
    path << "/#{params[:path]}" if (params[:path] && !params[:path].empty?)
    @scm_extensions = ScmExtensionsWrite.new(:path => path, :project => @project)

    if !request.get? && !request.xhr?
      path = params[:scm_extensions][:path].sub(/^#{path_root}/,'').sub(/^\//,'')
      new_name = params[:scm_extensions][:new_name]
      svnpath = path.empty? ? "/" : path

      if @repository.scm.respond_to?('scm_extensions_rename')
        ret = @repository.scm.scm_extensions_rename(@repository, svnpath, params[:scm_extensions][:new_name], params[:scm_extensions][:comments], nil)
        case ret
        when 0
          flash[:notice] = l(:notice_scm_extensions_rename_success)
          path = File.join(File.dirname(svnpath), new_name)
        when 1
          flash[:error] = l(:error_scm_extensions_rename_failed)
        end
      end
      @entry = @repository.entry(path, nil)
      isdir = (@entry.kind == "dir")
      action = (isdir ? 'show' : 'entry')
      path = format_path(path)
      if @repository.identifier.blank?
        redirect_to :controller => 'repositories', :action => action, :id => @project, :path => path
      else
        redirect_to :controller => 'repositories', :action => action, :id => @project, :repository_id => @repository.identifier, :path => path
      end
      return
    end
  end

  def move
    path_root = @repository.identifier.blank? ? "root" : @repository.identifier
    path = ""
    path << path_root
    path << "/#{params[:path]}" if (params[:path] && !params[:path].empty?)
    @scm_extensions = ScmExtensionsWrite.new(:path => path, :project => @project)

    if !request.get? && !request.xhr?
      path = params[:scm_extensions][:path].sub(/^#{path_root}/,'').sub(/^\//,'')
      svnpath = path.empty? ? "/" : path

      if @repository.scm.respond_to?('scm_extensions_move')
        ret = @repository.scm.scm_extensions_move(@repository, svnpath, params[:scm_extensions][:destination], params[:scm_extensions][:comments], nil)
        case ret
        when 0
          flash[:notice] = l(:notice_scm_extensions_move_success)
          path = File.join(params[:scm_extensions][:destination], File.basename(svnpath))
        when 1
          flash[:error] = l(:error_scm_extensions_move_failed_other)
        when 2
          flash[:error] = l(:error_scm_extensions_move_failed_same)
        when 3
          flash[:error] = l(:error_scm_extensions_move_failed_not_exist)
        end
      end
      @entry = @repository.entry(path, nil)
      isdir = (@entry.kind == "dir")
      action = (isdir ? 'show' : 'entry')
      path = format_path(path)
      if @repository.identifier.blank?
        redirect_to :controller => 'repositories', :action => action, :id => @project, :path => path
      else
        redirect_to :controller => 'repositories', :action => action, :id => @project, :repository_id => @repository.identifier, :path => path
      end
      return
    end
  end

  private

  def find_project
    @project = Project.find(params[:id])
    if params[:repository_id].present?
      @repository = @project.repositories.find_by_identifier_param(params[:repository_id])
    else
      @repository = @project.repository
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_repository
    @project = Project.find(params[:id])
    if params[:repository_id].present?
      @repository = @project.repositories.find_by_identifier_param(params[:repository_id])
    else
      @repository = @project.repository
    end
    (render_404; return false) unless @repository
    @path = (params[:path].kind_of?(Array) ? params[:path].join('/') : params[:path]) unless params[:path].nil?
    @path ||= ''
    @rev = params[:rev].blank? ? @repository.default_branch : params[:rev].strip
    @rev_to = params[:rev_to]
  rescue ActiveRecord::RecordNotFound
    render_404
  rescue InvalidRevisionParam
    show_error_not_found
  end

  def svn_target(repository, path = '')
    base = repository.url
    base = base.sub(/^.*:\/\/[^\/]*\//,"file:///svnroot/")
    uri = "#{base}/#{path}"
    uri = URI.escape(URI.escape(uri), '[]')
    shell_quote(uri.gsub(/[?<>\*]/, ''))
  end

  def gettmpdir(create = true)
    tmpdir = Dir.tmpdir
    t = Time.now.strftime("%Y%m%d")
    n = nil
    begin
      path = "#{tmpdir}/#{t}-#{$$}-#{rand(0x100000000).to_s(36)}"
      path << "-#{n}" if n
      Dir.mkdir(path, 0700)
      Dir.rmdir(path) unless create
    rescue Errno::EEXIST
      n ||= 0
      n += 1
      retry
    end

    if block_given?
      begin
        yield path
      ensure
        FileUtils.remove_entry_secure path if File.exist?(path)
        fname = "#{path}.txt"
        FileUtils.remove_entry_secure fname if File.exist?(fname)
      end
    else
      path
    end
  end

  def shell_quote(str)
    if Redmine::Platform.mswin?
      '"' + str.gsub(/"/, '\\"') + '"'
    else
      "'" + str.gsub(/'/, "'\"'\"'") + "'"
    end
  end

  def format_path(path)
    path = path.to_s.split(%r{[/\\]}).select {|p| !p.blank?}
    path = nil if path == []
    path
  end

end
