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
class ScmExtensionsRepositoryViewHook < Redmine::Hook::ViewListener
  def suburi(url)
    baseurl = Redmine::Utils.relative_url_root
    if not url.match(/^#{baseurl}/)
      url = baseurl + url
    end
    return url
  end
  def view_repositories_show_contextual(context = { })
    @project = context[:project]
    @repository = context[:repository]
    @path = context[:controller].instance_variable_get("@path")
    @revision = context[:controller].instance_variable_get("@rev")
    output = ""
    return output if !@repository.scm.respond_to?('scm_extensions_upload')
    return output if (@revision && !@revision.empty? && @revision != "HEAD"  && @repository.is_a?(Repository::Subversion))
    return output if !(User.current.allowed_to?(:scm_write_access, @project) && User.current.allowed_to?(:commit_access, @project))
    entry = @repository.entry(@path)
    output << "<table style='position: relative; top: -5px;' width='100%' border='0' cellpadding='0' cellspacing='0'><tr><td style='width: 1%; white-space:nowrap;text-align: left;'>"
    if entry.is_dir?
      url = suburi(url_for(:controller => 'scm_extensions', :action => 'upload', :id => @project, :repository_id => @repository.identifier, :path => @path, :only_path => true))
      output << "<a class='icon icon-add' href='#{url}'>#{l(:label_scm_extensions_upload)}</a>" if @repository.scm.respond_to?('scm_extensions_upload')
      #output << link_to(l(:label_scm_extensions_upload), {:controller => 'scm_extensions', :action => 'upload', :id => @project, :repository_id => @repository.identifier, :path => @path, :only_path => true}, :class => 'icon icon-add') if @repository.scm.respond_to?('scm_extensions_upload')
      output << "&nbsp;&nbsp;"
      url = suburi(url_for(:controller => 'scm_extensions', :action => 'upload_folder', :id => @project, :repository_id => @repository.identifier, :path => @path, :only_path => true))
      output << "<a class='icon icon-add' href='#{url}'>#{l(:label_scm_extensions_upload_folder)}</a>" if @repository.scm.respond_to?('scm_extensions_upload_folder')
      #output << link_to(l(:label_scm_extensions_upload), {:controller => 'scm_extensions', :action => 'upload', :id => @project, :repository_id => @repository.identifier, :path => @path, :only_path => true}, :class => 'icon icon-add') if @repository.scm.respond_to?('scm_extensions_upload')
      output << "&nbsp;&nbsp;"
      #output << link_to(l(:label_scm_extensions_new_folder), {:controller => 'scm_extensions', :action => 'mkdir', :id => @project, :repository_id => @repository.identifier, :path => @path, :only_path => true}, :class => 'icon icon-add') if @repository.scm.respond_to?('scm_extensions_mkdir')
      url = suburi(url_for(:controller => 'scm_extensions', :action => 'mkdir', :id => @project, :repository_id => @repository.identifier, :path => @path, :only_path => true))
      output << "<a class='icon icon-add' href='#{url}'>#{l(:label_scm_extensions_new_folder)}</a>" if @repository.scm.respond_to?('scm_extensions_mkdir')
      output << "&nbsp;&nbsp;"
      if @path && !@path.empty?
        #output << link_to(l(:label_scm_extensions_delete_folder), {:controller => 'scm_extensions', :action => 'delete', :id => @project, :repository_id => @repository.identifier, :path => @path, :only_path => true},  :class => 'icon icon-del', :confirm => l(:text_are_you_sure)) if @repository.scm.respond_to?('scm_extensions_delete')
        url = suburi(url_for(:controller => 'scm_extensions', :action => 'delete', :id => @project, :repository_id => @repository.identifier, :path => @path, :only_path => true))
        output << "<a class='icon icon-del' data-confirm='#{l(:text_are_you_sure)}' href='#{url}'>#{l(:label_scm_extensions_delete_folder)}</a>" if @repository.scm.respond_to?('scm_extensions_delete')
        output << "&nbsp;&nbsp;"
      end
      # calculate folder size: https://stackoverflow.com/questions/55719522/how-to-get-the-total-size-of-files-in-a-directory-in-ruby
      full_path = File.join(@repository.url, @path) + "/**/*"
      total_size = Dir[full_path].select { |f| File.file?(f) }.sum { |f| File.stat(f).blocks * 512 }
      # unit: byte -> MB
      total_size /= (1024.0 * 1024.0)
      # FIXME: number_field_tag returns string?
      Rails.logger.info "upper limit: #{Setting.plugin_redmine_scm_extensions['download_folder_upper_limit']}, class: #{Setting.plugin_redmine_scm_extensions['download_folder_upper_limit'].class}"
      Rails.logger.info "#{total_size} bigger than #{Setting.plugin_redmine_scm_extensions['download_folder_upper_limit'].to_i}?"
      disabled = (total_size > Setting.plugin_redmine_scm_extensions['download_folder_upper_limit'].to_i)

      # url = suburi(url_for(:controller => 'scm_extensions', :action => 'download', :id => @project, :repository_id => @repository.identifier, :path => @path, :only_path => true))
      # output << "<a class='icon icon-download' href='#{url}'>#{l(:label_scm_extensions_download_folder)}</a>"

      output << "<div style='display: inline-block'>"
      if disabled
        output << "<div title='#{l(:label_scm_extensions_downloadable_info)}' rel='tooltip' style='display: inline-block'>"
      end
      # params: https://stackoverflow.com/questions/4886963/how-to-add-additional-params-to-a-button-to-form
      # :method => get: https://stackoverflow.com/questions/8684467/button-to-with-get-method-option-in-rails/21011565
      # use 'get' rather than 'post' to avoid "Can't verify CSRF token authenticity."
      output << button_to(l(:label_scm_extensions_download_folder), {:controller => 'scm_extensions', :action => 'download', :id => @project}, :disabled => disabled, :method => 'get', :params => {:repository_id => @repository.identifier, :path => @path})
      if @path && !@path.empty?
        output << "&nbsp;&nbsp;"
        url = suburi(url_for(:controller => 'scm_extensions', :action => 'rename', :id => @project, :repository_id => @repository.identifier, :path => @path, :only_path => true))
        output << "<a class='icon icon-edit' href='#{url}'>#{l(:label_scm_extensions_rename)}</a>" if @repository.scm.respond_to?('scm_extensions_rename')
      end
      if @path && !@path.empty?
        output << "&nbsp;&nbsp;"
        url = suburi(url_for(:controller => 'scm_extensions', :action => 'move', :id => @project, :repository_id => @repository.identifier, :path => @path, :only_path => true))
        output << "<a class='icon icon-move' href='#{url}'>#{l(:label_scm_extensions_move)}</a>" if @repository.scm.respond_to?('scm_extensions_move')
      end
      output << "</div>"
    else
      #output << link_to(l(:label_scm_extensions_delete_file), {:controller => 'scm_extensions', :action => 'delete', :id => @project, :repository_id => @repository.identifier, :path => @path, :only_path => true},  :class => 'icon icon-del', :confirm => l(:text_are_you_sure)) if @repository.scm.respond_to?('scm_extensions_delete')
      url = suburi(url_for(:controller => 'scm_extensions', :action => 'delete', :id => @project, :repository_id => @repository.identifier, :path => @path, :only_path => true))
      output << "<a class='icon icon-del' data-confirm='#{l(:text_are_you_sure)}' href='#{url}'>#{l(:label_scm_extensions_delete_file)}</a>" if @repository.scm.respond_to?('scm_extensions_delete')
      output << "&nbsp;&nbsp;"
      url = suburi(url_for(:controller => 'scm_extensions', :action => 'rename', :id => @project, :repository_id => @repository.identifier, :path => @path, :only_path => true))
      output << "<a class='icon icon-edit' href='#{url}'>#{l(:label_scm_extensions_rename)}</a>" if @repository.scm.respond_to?('scm_extensions_rename')
      url = suburi(url_for(:controller => 'scm_extensions', :action => 'move', :id => @project, :repository_id => @repository.identifier, :path => @path, :only_path => true))
      output << "<a class='icon icon-move' href='#{url}'>#{l(:label_scm_extensions_move)}</a>" if @repository.scm.respond_to?('scm_extensions_move')
    end
    output << "&nbsp;&nbsp;"
    url = suburi(url_for(:controller => 'scm_extensions', :action => 'notify', :id => @project, :repository_id => @repository.identifier, :path => @path, :only_path => true))
    output << "<a class='icon icon-comment' href='#{url}'>#{l(:label_scm_extensions_notify)}</a>"
    output << "</td>"
    if User.current.allowed_to?(:synapse_access, @project)
      output << "<td syle='width: 98%'> </td><td style='text-align: right; width: 1%; white-space:nowrap;'>"
      options={}
      options[:target]='_blank'
      begin
        if @repository.is_a?(Repository::Filesystem)
          rootdir = @repository.scm.url
          mountdir = rootdir.sub(/\/files$/, '')
          repo_size=""
          repo_size = `/opt/appli/checksize #{mountdir}  #{@project.identifier}` if File.exist?("/opt/appli/checksize")
          output << repo_size + "&nbsp;&nbsp;"
        end
        if !Setting.plugin_redmine_synapse['url_help_files'].empty?
          url = Setting.plugin_redmine_synapse['url_help_files']
          link = "<a href='" + url + "' target='_blank' class='icon icon-help'>"+ l(:label_help) + "</a>"
          output << "&nbsp;&nbsp;#{link}"
        end
        if !Setting.plugin_redmine_synapse['url_video_files'].empty?
          url = Setting.plugin_redmine_synapse['url_video_files']
          link = "<a href='" + url + "' target='_blank' class='icon icon-help'>"+ l(:label_synapse_video) + "</a>"
          output << "&nbsp;&nbsp;#{link}"
        end
      rescue
        output << ""
      end
      output << "</td>"
    else
      output << "<td width: 99%'> </td>"
    end
    output << "</tr></table>"
    return output
  end
end
