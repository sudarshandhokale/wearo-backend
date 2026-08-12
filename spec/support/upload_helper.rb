require "base64"

module UploadHelper
  PNG_BYTES = Base64.decode64(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII="
  ).freeze

  def uploaded_png(name = "shirt.png", bytes: PNG_BYTES)
    file = Tempfile.new([ File.basename(name, ".png"), ".png" ])
    file.binmode
    file.write(bytes)
    file.rewind

    Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: name)
  end
end
