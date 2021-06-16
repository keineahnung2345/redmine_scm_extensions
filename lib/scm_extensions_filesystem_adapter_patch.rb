# SCM Extensions plugin for Redmine
# Copyright (C) 2010 Arnaud MARTEL
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

require 'zip'

module ScmExtensionsFilesystemAdapterPatch
  def self.included(base) # :nodoc:
    base.send(:include, FilesystemAdapterMethodsScmExtensions)

    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
    end

  end
end

module FilesystemAdapterMethodsScmExtensions

  def scm_extensions_upload(repository, folder_path, attachments, comments, identifier)
    return -1 if attachments.nil? || !attachments.is_a?(ActionController::Parameters)
    return -1 if scm_extensions_invalid_path(folder_path)
    metapath = (self.url =~ /\/files\/$/ && File.exist?(self.url.sub(/\/files\//, "/attributes")))

    rev = identifier ? "@{identifier}" : ""
    fullpath = File.join(repository.scm.url, folder_path)
    if File.exist?(fullpath) && File.directory?(fullpath)
      error = false

      if repository.supports_all_revisions?
        rev = -1
        rev = repository.latest_changeset.revision.to_i if repository.latest_changeset
        rev = rev + 1
        changeset = Changeset.create(:repository => repository,
                                                 :revision => rev, 
                                                 :committer => User.current.login, 
                                                 :committed_on => Time.now,
                                                 :comments => comments)
      
      end
      attachments.require(attachments.keys).each do |attachment|
        ajaxuploaded = true #attachment.has_key?("authenticity_token")

        if ajaxuploaded
          filename = attachment['filename']
          tmp_att = Attachment.find_by(filename: filename)
          file = tmp_att.diskfile
        else
          file = attachment['file']
          next unless file && file.size > 0 && !error
          filename = File.basename(file.original_filename)
          next if scm_extensions_invalid_path(filename)
        end      
        
        begin
          if repository.supports_all_revisions?
            action = "A"
            action = "M" if File.exists?(File.join(repository.scm.url, folder_path, filename))
            Change.create( :changeset => changeset, :action => action, :path => File.join("/", folder_path, filename))
          end
          outfile = File.join(repository.scm.url, folder_path, filename)
          if ajaxuploaded
            if File.exist?(outfile)
              File.delete(outfile)
            end
            FileUtils.mv file, outfile
            tmp_att.destroy
          else
            File.open(outfile, "wb") do |f|
              buffer = ""
              while (buffer = file.read(8192))
                f.write(buffer)
              end
            end
          end
          if metapath
            metapathtarget = File.join(repository.scm.url, folder_path, filename).sub(/\/files\//, "/attributes/")
            FileUtils.mkdir_p File.dirname(metapathtarget)
            File.open(metapathtarget, "w") do |f|
              f.write("#{User.current}\n")
              f.write("#{rev}\n")
            end
          end

        rescue
          error = true
        end
      end

      if error
        return 1
      else
        return 0
      end
    else
      return 2
    end
  end

  # upload a compressed file and then extract it as a folder
  def scm_extensions_upload_folder(repository, folder_path, attachments, comments, identifier)
    return -1 if attachments.nil? || !attachments.is_a?(ActionController::Parameters)
    return -1 if scm_extensions_invalid_path(folder_path)
    metapath = (self.url =~ /\/files\/$/ && File.exist?(self.url.sub(/\/files\//, "/attributes")))

    rev = identifier ? "@{identifier}" : ""
    fullpath = File.join(repository.scm.url, folder_path)
    if File.exist?(fullpath) && File.directory?(fullpath)
      error = false

      if repository.supports_all_revisions?
        rev = -1
        rev = repository.latest_changeset.revision.to_i if repository.latest_changeset
        rev = rev + 1
        changeset = Changeset.create(:repository => repository,
                                                 :revision => rev,
                                                 :committer => User.current.login,
                                                 :committed_on => Time.now,
                                                 :comments => comments)

      end

      supported_compressed_type = %w(.zip .rar .7z .tar .tar.gz)

      attachments.require(attachments.keys).each do |attachment|
        ajaxuploaded = true #attachment.has_key?("authenticity_token")

        if ajaxuploaded
          filename = attachment['filename']
          # TODO: if there are multiple attachments with same name, choose the last one
          tmp_att = Attachment.find_by(filename: filename)
          file = tmp_att.diskfile
        else
          file = attachment['file']
          next unless file && file.size > 0 && !error
          filename = File.basename(file.original_filename)
          next if scm_extensions_invalid_path(filename)
        end

        unless filename.downcase.ends_with?(*supported_compressed_type)
          return 3
        end

        foldername = filename.gsub(/.zip|.rar|.7z|.tar|.tar.gz$/, "")

        begin
          if repository.supports_all_revisions?
            action = "A"
            action = "M" if Dir.exists?(File.join(repository.scm.url, folder_path, foldername))
            Change.create( :changeset => changeset, :action => action, :path => File.join("/", folder_path, foldername))
          end
          outfolder = File.join(repository.scm.url, folder_path)
          if ajaxuploaded
            if Dir.exist?(File.join(outfolder, foldername))
              # TODO: add confirmation
              FileUtils.rm_rf(File.join(outfolder, foldername))
            end
            # TODO: ask if the user want to keep the name of the compressed file and make it the outermost folder
            #extract_zip(file, outfolder)
            extract_compressed_file(file, outfolder)
            tmp_att.destroy
            # make sure "file" is a zip file,
            # unzip it

            # move the directory to "folder_path"
          end
          # TODO: support metapath
          if false #if metapath
            metapathtarget = File.join(repository.scm.url, folder_path, filename).sub(/\/files\//, "/attributes/")
            FileUtils.mkdir_p File.dirname(metapathtarget)
            File.open(metapathtarget, "w") do |f|
              f.write("#{User.current}\n")
              f.write("#{rev}\n")
            end
          end

        rescue
          error = true
        end
      end

      if error
        return 1
      else
        return 0
      end
    else
      return 2
    end
  end

  def scm_extensions_delete(repository, path, comments, identifier)
    return -1 if path.nil? || path.empty?
    return -1 if scm_extensions_invalid_path(path)
    metapath = (self.url =~ /\/files\/$/ && File.exist?(self.url.sub(/\/files\//, "/attributes")))
    if File.exist?(File.join(repository.scm.url, path)) && path != "/"
      error = false

      begin
        if repository.supports_all_revisions?
          rev = -1
          rev = repository.latest_changeset.revision.to_i if repository.latest_changeset
          rev = rev + 1
          changeset = Changeset.create(:repository => repository,
                                                   :revision => rev, 
                                                   :committer => User.current.login, 
                                                   :committed_on => Time.now,
                                                   :comments => comments)
          Change.create( :changeset => changeset, :action => 'D', :path => File.join("/", path))
        end
          
      FileUtils.remove_entry_secure File.join(repository.scm.url, path)
      if metapath
        metapathtarget = File.join(repository.scm.url, path).sub(/\/files\//, "/attributes/")
        FileUtils.remove_entry_secure metapathtarget if File.exist?(metapathtarget)
      end
      rescue
        error = true
      end

      return error ? 1 : 0
    end
  end

  def scm_extensions_mkdir(repository, path, comments, identifier)
    return -1 if path.nil? || path.empty?
    return -1 if scm_extensions_invalid_path(path)

    error = false
    begin
      if repository.supports_all_revisions?
        rev = -1
        rev = repository.latest_changeset.revision.to_i if repository.latest_changeset
        rev = rev + 1
        changeset = Changeset.create(:repository => repository,
                                                 :revision => rev, 
                                                 :committer => User.current.login, 
                                                 :committed_on => Time.now,
                                                 :comments => "created folder: #{path}")
        Change.create( :changeset => changeset, :action => 'A', :path => File.join("/", path))
      end
      Dir.mkdir(File.join(repository.scm.url, path))
    rescue
      error = true
    end

    return error ? 1 : 0
  end

  def scm_extensions_download(repository, path, rev, identifier)
  end

  def scm_extensions_invalid_path(path)
    return path =~ /\/\.\.\//
  end

  private

  def extract_zip(file, destination)
    FileUtils.mkdir_p(destination)
 
    Zip::File.open(file) do |zip_file|
      zip_file.each do |f|
        fpath = File.join(destination, f.name)
        zip_file.extract(f, fpath) unless File.exist?(fpath)
      end
    end
  end

  def extract_rar(fname, destination)
    # FIXME: cannot recover docx file
    FileUtils.mkdir_p(destination)

    cmd = ["unrar x -o+", fname, destination].join(" ")
    system(cmd)
  end

  def extract_compressed_file(fname, destination)
    FileUtils.mkdir_p(destination)

    if fname.downcase.ends_with?(".rar")
      extract_rar(fname, destination)
    else
      flags = Archive::EXTRACT_PERM
      reader = Archive::Reader.open_filename(fname)

      reader.each_entry do |entry|
        reader.extract(entry, flags.to_i, destination: destination)
      end
      reader.close
    end
  end

end

Redmine::Scm::Adapters::FilesystemAdapter.send(:include, ScmExtensionsFilesystemAdapterPatch)
