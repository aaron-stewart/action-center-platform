Actioncenter::Application.routes.draw do
  get "robots.txt", controller: :robots, action: :show, format: 'text'
  get "/heartbeat", to: "robots#heartbeat"

  # Root - Redundant - TODO - refactor
  get "welcome/index"
  root 'welcome#index'

  # EFF TOOLS (Call, Share, Petition) - External Reusable Services

  post "tools/call"
  post "tools/petition"
  post "tools/tweet"
  post "tools/email"
  post "tools/message-congress"
  get "tools/reps"
  get "tools/reps_raw"
  get "tools/social_buttons_count"

  get "smarty_streets/:action", controller: :smarty_streets
  get "petition/:id/recent_signatures", :to => "petition#recent_signatures", :format => 'json'

  # Handle notifications from Amazon SES
  post "bounce/:amazon_authorize_key", :to => "sns#bounce", :format => 'json'
  post "complaint/:amazon_authorize_key", :to => "sns#complaint", :format => 'json'

  get "ahoy/visit"

  # EFF Resources

  devise_for :users, path: '', path_names:  {sign_in:  'login',
                                             sign_out: 'logout',
                                             sign_up:  'register'},
                               controllers: {sessions: 'sessions', registrations: 'registrations'}

  scope :csrf_protection, controller: "csrf_protection" do
    get :meta_tags
    get :authenticity_token
  end

  devise_scope :user do
    get "/sessions/password_reset" => "sessions#password_reset"
  end

  resource :user, path: 'account', only: [:show, :edit, :update] do
    member do
      delete :clear_activity
    end
  end

  # override devise's user_root (defaults to site root)
  get 'account', to: 'users#show', as: 'user_root'

  resources :action_page, path: :action do
    member do
      get :embed_iframe
      get :signature_count
      get :filter
      get ':institution_id' => :show_by_institution, as: :institution
    end
    collection do
      get :embed
    end
  end

  resources :subscriptions, only: :create

  resources :partners, only: [:show, :edit, :update] do
    member do
      get :csv
      get :presentable_csv
      post 'users' => 'partners#add_user', as: :add_user
      delete 'users/:user_id' => 'partners#remove_user', as: :remove_user
    end
  end

  namespace :admin do

    resources :source_files, :only => [:index, :create, :destroy], :controller => 's3_uploads' do
      get :generate_key, :on => :collection
    end

    get 'mailer/:action/:id' => 'mailer#:action'

    resources :petitions, only: :show do
      member do
        get :csv
        get :presentable_csv
        delete "signatures" => "petitions#destroy_signatures", as: :signatures
      end
    end

    resources :congress_message_campaigns, only: :none do
      member do
        get :date_tabulation
        get :congress_tabulation
        get "staffer_report/:bioguide_id", to: "congress_message_campaigns#staffer_report", as: :staffer_report
      end
    end

    resources :em
    resources :partners, except: [:show, :edit, :update]
    resources :topic_categories, :topic_sets, :topics

    resources :action_pages do
      get :publish
      get :unpublish
      get :destroy
      post 'update_featured_pages', :on => :collection
      patch :preview
      resources :affiliation_types, only: [:index, :new, :create, :destroy]
      resources :institutions, except: [:show, :edit, :update] do
        match :import, via: :post, on: :collection
        match :index, via: :delete, on: :collection, action: :destroy_all
      end
    end

    resources :users, only: [:index, :update]

    get "images", to: "images#index"
  end

  resources :congress, only: [:index] do
    collection do
      get :search
    end
  end

  scope "phantomdc", controller: "phantom_dc" do
    post "retrieve-form-elements"
    post "fill-out-form"
    post "fill-out-captcha"

    get "recent-fill-image/:bio_id", action: "recent_fill_image"
    get "recent-fill-status/:bio_id", action: "recent_fill_status"
    get "recent-statuses-detailed/:bio_id", action: "recent_statuses_detailed"
    get "list-actions/:bio_id", action: "list_actions"
    get "list-congress-members", action: "list_congress_members"
    get "successful-fills-by-date/:bio_id", action: "successful_fills_by_date"
    get "successful-fills-by-member/:bio_id", action: "successful_fills_by_member"
  end
end
