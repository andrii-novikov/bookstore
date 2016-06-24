module Facebook
  extend ActiveSupport::Concern

  def is_facebook_account
    self[:provider].present? && self[:uid].present?
  end

  def check_facebook(provider, uid)
    self[:provider] == provider && self[:uid] == uid
  end

  def sign_in_with_facebook(params)
    if is_facebook_account
      return true if check_facebook(params[:provider], params[:uid])
      errors.add(:base, "#{params[:email]} is attach for another account")
    else
      user.update(params)
    end
  end

  module ClassMethods
    def from_omniauth(auth)
      auth_params = {
          provider: auth.provider,
          uid: auth.uid,
          name:auth.info.name,
          email:auth.info.email
      }

      user = find_by_email(auth_params[:email])

      if user.present?
        user.sign_in_with_facebook(auth_params) ?
            user :
            nil
      else
        auth_params[:password] = Devise.friendly_token[0,20]
        User.create(auth_params)
      end
    end

    def new_with_session(params, session)
      super.tap do |user|
        data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        if data
          user.email = data["email"] if user.email.blank?
        end
      end
    end
  end
end