class Auth::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def qiita
    auth = request.env['omniauth.auth']
    if current_user
      QiitaAccount.find_or_create_by(user: current_user) do |account|
        account.url_name = auth.url_name
      end
    else
      account = QiitaAccount.find_by(url_name: auth.url_name)
      sign_in account.user if account
    end

    if current_user
      redirect_to root_path
    else
      redirect_to new_user_registration_path
    end
  end
end
