module Admin
  class UsersController < BaseController
    before_filter :load_user

    def edit
    end

    def update
      old = @user.attributes.dup

      if @user.update(user_params)
        if old['email'] != @user.email
          @user.send_email_change_confirmation(old['email'])
        end

        flash[:success] = 'User has been successfully updated.'
      else
        flash[:error] = 'Failed to update user.'
      end

      render 'edit'
    end

    private

    def load_user
      @user = User.find_by_username!(params[:username])
    end

    def user_params
      params.required(:user).permit(attributes)
    end

    def attributes
      %i(fullname username email account_status)
    end

  end
end
