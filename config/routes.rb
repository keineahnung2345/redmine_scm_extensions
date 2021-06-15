#map.connect ':controller/:action/:id'
match 'projects/:id/scm_extensions/upload', :controller => 'scm_extensions', :action => :upload, :via => [:get, :post]
match 'projects/:id/scm_extensions/upload_folder', :controller => 'scm_extensions', :action => :upload_folder, :via => [:get, :post]
match 'projects/:id/scm_extensions/delete', :controller => 'scm_extensions', :action => :delete, :via => [:get, :post]
match 'projects/:id/scm_extensions/mkdir', :controller => 'scm_extensions', :action => :mkdir, :via => [:get, :post]
match 'projects/:id/scm_extensions/show', :controller => 'scm_extensions', :action => :show, :via => [:get, :post]
match 'projects/:id/scm_extensions/download', :controller => 'scm_extensions', :action => :download, :via => [:get, :post]
match 'projects/:id/scm_extensions/notify', :controller => 'scm_extensions', :action => :notify, :via => [:get, :post]
