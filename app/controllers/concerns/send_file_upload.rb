module SendFileUpload
  def send_upload(file_upload, send_params: {}, redirect_params: {}, attachment: nil, disposition: 'attachment')
    if attachment
      # Response-Content-Type will not override an existing Content-Type in Google Cloud Storage
      redirect_params[:query] = { "response-content-disposition" => "#{disposition};filename=#{attachment.inspect}",
                                  "response-content-type" => guess_content_type(attachment) }
      # By default, Rails will send uploads with an extension of .js with a
      # content-type of text/javascript, which will trigger Rails'
      # cross-origin JavaScript protection.
      send_params[:content_type] = 'text/plain' if File.extname(attachment) == '.js'
      send_params.merge!(filename: attachment, disposition: disposition)
    end

    if file_upload.file_storage?
      send_file file_upload.path, send_params
    elsif file_upload.class.proxy_download_enabled?
      headers.store(*Gitlab::Workhorse.send_url(file_upload.url(**redirect_params)))
      head :ok
    else
      redirect_to file_upload.url(**redirect_params)
    end
  end

  def guess_content_type(filename)
    mime_type = MIME::Types.type_for(filename)

    return "application/octet-stream" unless mime_type

    mime_type.first.content_type
  end
end
