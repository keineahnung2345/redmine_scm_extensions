class ScmExtensionsMailer < Mailer
  def send_upload(user, obj, attachments, language, rec )
    @obj = obj
    @attachments = attachments
    set_language_if_valid language
    path_root = @obj.repository.identifier.blank? ? 'root' : @obj.repository.identifier
    sub = l(:label_scm_extensions_upload_subject, obj.project.name)
    reg = Regexp.new("^#{path_root}")
    @folder_path = @obj.path.sub(reg,'').sub(/^\//,'')
    mail(to: rec, subject: sub, 'From': user.mail, 'Reply-To': user.mail)
  end

  def notify(user, obj, selectedfiles, language, rec )
    @obj = obj
    @selectedfiles = selectedfiles
    set_language_if_valid language
    path_root = @obj.repository.identifier.blank? ? 'root' : @obj.repository.identifier
    sub = l(:label_scm_extensions_upload_subject, obj.project.name)
    reg = Regexp.new("^#{path_root}")
    @folder_path = @obj.path.sub(reg,'').sub(/^\//,'')
    if @obj.repository.entry(@folder_path).kind == 'file'
      @folder_path = File.dirname(@folder_path)
    end
    # the receiver will be in the BCC field
    mail(to: rec, cc: nil, subject: sub,'From': user.mail, 'Reply-To': user.mail)
  end
end
