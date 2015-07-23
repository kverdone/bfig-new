class AddReferralFieldsToUser < ActiveRecord::Migration
  def change
    add_column :users, :referral_code, :string
    add_column :users, :referring_user_id, :integer
    add_column :users, :verified, :boolean
    add_column :users, :signup_referral_code, :string
  end
end
