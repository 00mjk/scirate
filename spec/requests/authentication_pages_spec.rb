require 'spec_helper'

describe "google signup" do
  let(:mock_auth) { MockAuth.google }

  before do
    OmniAuth.config.mock_auth[:google_oauth2] = mock_auth
  end

  it "should allow signup via google" do
    visit login_path
    click_link "Sign in with Google"
    expect(page).to have_content "about to create a new SciRate account"
    expect(page).to have_content "Google"
    expect(page).to have_content mock_auth.info.email

    click_button "Confirm And Create This Account"
    expect(page).to have_content "Sign out"

    user = User.where(email: mock_auth.info.email).first
    expect(user.active?).to be_true
  end

  it "should handle the case when email is taken" do
    FactoryGirl.create(:user, email: mock_auth.info.email)

    visit login_path
    click_link "Sign in with Google"
    p page.text
    expect(page).to have_error_message "please visit your settings page"
  end

  it "should allow login after account creation" do
    AuthLink.from_omniauth(mock_auth).create_user!

    visit login_path
    click_link "Sign in with Google"

    expect(page).to have_content "Sign out"
  end
end

describe "Authentication" do

  subject { page }

  describe "signin" do
    before { visit login_path }

    it "shouldn't allow invalid information" do
      click_button "Sign in"

      page.should have_error_message "Invalid"
    end

    it "should sign in and out correctly" do
      user = FactoryGirl.create(:user)
      sign_in(user)

      page.should have_title "Home feed"
      page.should have_link('Profile', href: user_path(user))
      page.should have_link('Settings', href: settings_path)
      page.should have_link('Sign out', href: logout_path)
      page.should_not have_link('Sign in', href: login_path)

      sign_out
      page.should have_title('Top arXiv papers')
      page.should_not have_link('Sign out', href: logout_path)
      page.should_not have_link('Profile', href: user_path(user))
      page.should_not have_link('Settings', href: settings_path)
    end
  end

  describe "authorization" do
    describe "for non-signed-in users" do
      let(:user) { FactoryGirl.create(:user) }

      describe "in the Users controller" do

        describe "visiting the edit page" do
          before { visit admin_edit_user_path(user) }
          it { should have_title 'Sign in' }
        end

        describe "submitting to the update action" do
          before { patch admin_user_path(user) }
          specify { response.should redirect_to(login_path) }
        end
      end
    end

    describe "as wrong user" do
      let(:user) { FactoryGirl.create(:user) }
      let(:wrong_user) { FactoryGirl.create(:user, email: "wrong@example.com") }
      before { sign_in user }

      describe "visiting Users#edit page" do
        before { visit edit_admin_user_path(wrong_user) }

        it { should have_title '' }
      end

      describe "submitting to the Users#update action" do
        before do
          patch admin_user_path(wrong_user)
        end

        specify { response.should redirect_to(root_path) }
      end
    end

    describe "as signed-in user" do
      let(:user) { FactoryGirl.create(:user) }
      before { sign_in user }

      describe "submitting a GET request to the Users#new action" do
        before do
          get signup_path
        end

        specify { response.should redirect_to(root_path) }
      end

      describe "submitting a POST request to the Users#create action" do
        before do
          post signup_path
        end

        specify { response.should redirect_to(root_path) }
      end
    end

    describe "for non-signed-in users" do
      let(:user) { FactoryGirl.create(:user) }
      let(:paper){ FactoryFirl.create(:paper) }

      describe "when attempting to visit a protected page" do
        before do
          visit admin_edit_user_path(user)
          fill_in "Email",    with: user.email
          fill_in "Password", with: user.password
          click_button "Sign in"
        end

#        describe "after signing in" do
#          it "should render the desired protected page" do
#            page.should have_title 'Edit user'
#          end
#        end

        describe "when signing in again" do
          before { sign_in user }

          it "should render the (default) home feed" do
            page.should have_title "Home feed"
          end
        end
      end
    end
  end
end
