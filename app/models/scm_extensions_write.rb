class ScmExtensionsWrite

  #acts_as_watchable

  attr_accessor :comments
  attr_accessor :new_folder
  attr_accessor :path
  attr_accessor :project
  attr_accessor :recipients
  attr_accessor :repository

  def initialize(options = { })
    self.comments = options[:comments]
    self.new_folder = options[:new_folder]
    self.path = options[:path]
    self.project = options[:project]
    self.repository = options[:repository]
    self.recipients = {}
  end

  def deliver(attachments)
    ScmExtensionsMailer.send_upload(self, attachments).deliver
      return true
  end

  def notify(selectedfiles)
    ScmExtensionsMailer.notify(self, selectedfiles).deliver
      return true
  end
end
