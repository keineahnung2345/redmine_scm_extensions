# Introduction

Main features of the plugin:
- Add 5 actions in repository views: **upload files**, **upload folders via compressed files**, **new folder**, **delete file/folder** and **download folders**. Right now, only ~~subversion(not fixed for Redmine 4.1 yet)~~ and filesystem SCM are supported...
- Add a new macro _scm_show_ to include repository inside a wiki page 

Development was done using REDMINE trunk r9901 (=> 2.0.3 +) and any release after 2.0.3 should work

About subversion support:
To commit changes in Subversion, the plugin opens the repository with the file protocol. For this reason, you need the following:
- The repositories have to be installed on the REDMINE server.
- Plugin will replace the beginning of your repository location ([protocol]://[server]/" with "file:///svnroot/". You may need to create a symbolic link /svnroot for this to work...  

# Setup

### 1. Install requirements

[zip-zip](https://rubygems.org/gems/zip-zip/versions/0.3)

[ffi-libarchive](https://github.com/chef/ffi-libarchive)

### 2. Install plugin into vendor/plugins

Install redmine_scm_extensions with:
- <tt>cd [redmine-install-dir]/plugins</tt>
- <tt>git clone git://github.com/amartel/redmine_scm_extensions.git</tt>

No DB migration is required...

### 3. Restart your web server


### 4. Configure REDMINE with your web browser

If everything is OK, you should see SCM extensions in the plugin list (Administration -> Plugins)

A new permission is now available (SCM extensions -> Update repository) and you have to assign it to the roles you need


# History

0.4.0: 
- New: add button to send a notification email about existing files
- New: redmine 2.3.0 or higher is required

0.3.0: 2012-08-21
- New: redmine 2.0.3 or higher is required

0.2.0: 2012-01-18
- New: redmine 1.3.1 or higher is required (support for multi-repositories)

0.1.0: 2011-01-14
- Fixed: support for redmine 1.1.0 (icon display)

0.0.2: 2010-08-03
- New: support for filesystem SCM
- New: Members can be selected in upload form and the plugin will notify them by email if upload complete successfully

0.0.1: Initial release

# TODO

- [x] Update to Redmine 4.1 for filesystem SCM
- [ ] Update to Redmine 4.1 for subversion SCM
- [ ] Add git SCM support(?)
- [x] Upload folders via compressed files
- [ ] Upload folders directly(?)
- [x] Download folders
- [ ] Rename files/folders
- [ ] Move files/folders
