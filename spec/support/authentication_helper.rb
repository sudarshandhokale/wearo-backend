module AuthenticationHelper
  def auth_headers(user)
    { "Authorization" => "Bearer #{Auth::Token.encode(user)}" }
  end
end
