# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2011-20 Karel Pičman <karel.picman@kontron.com>
# Copyright © 2021    keineahnung2345 <mimifasosofamire1123@gmail.com
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
require 'redmine/scm/adapters'

module SCMExtensionsZip
  class Zip
    attr_reader :files

    def initialize
      @temp_file = Tempfile.new(%w(scm_extensions_zip_ .zip), Pathname.new(Dir.tmpdir))
      @zip_file = ::Zip::OutputStream.open(@temp_file)
    end

    def finish
      @zip_file.close
      @temp_file.path
    end

    def close
      @zip_file.close
    end

    def add_file(repository, path = nil, rev = nil, root_path = nil)
      file = repository.entry(path, rev)
      if file.is_dir? then return end
      rel_path = path.sub(root_path, "")
      rel_path = rel_path[1...] if rel_path.starts_with?("/")
      mod_time = file && file.lastrev ? file.lastrev.time : Time.now
      zip_entry = ::Zip::Entry.new(@zip_file, rel_path, nil, nil, nil, nil, nil, nil,
                                   ::Zip::DOSTime.at(mod_time))
      @zip_file.put_next_entry(zip_entry)
      full_path = repository.url + File::SEPARATOR + path
      File.open(full_path, 'rb') do |f|
         while (buffer = f.read(8192))
           @zip_file.write(buffer)
         end
      end
    end

    def add_folder(repository, path = nil, rev = nil, root_path = nil)
      folder = repository.entry(path, rev)
      rel_path = path.sub(root_path, "")
      rel_path = rel_path[1...] if rel_path.starts_with?("/")
      unless rel_path.empty?
        if rel_path.last != File::SEPARATOR then rel_path = rel_path + File::SEPARATOR end
        zip_entry = ::Zip::Entry.new(@zip_file, rel_path, nil, nil, nil, nil, nil, nil,
                                                     ::Zip::DOSTime.at(folder.lastrev.time))
        @zip_file.put_next_entry(zip_entry)
      end
      _entries = repository.entries(path, rev)
      _entries.each do |entry|
        if entry.is_dir?
          add_folder(repository, entry.path, rev, root_path)
        else
          add_file(repository, entry.path, rev, root_path)
        end
      end
    end
  end
end
