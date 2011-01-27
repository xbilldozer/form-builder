Rails.application.routes.draw do

  resources :test do
    member do
      post :save
    end
  end
  
  namespace :admin do
    
    resources :forms do
      
      collection do
        get :search
        get       :new_form
        get       :new_child
        post      :create_form
        post      :create_child_form
      end

      member do
        post      :set_parent
        post      :orphan_child
        get       :display
        post      :publish
      end
    
      resources :form_fields, :except => [:show] do
        member do
          get     :options
          get     :validations
          get     :dependencies
          
          post    :create_option
          post    :create_validation
          post    :create_dependency
          
          delete  :destroy_option
          delete  :destroy_validation
          delete  :destroy_dependency
        end
      end
    
    end
    
  end

end
