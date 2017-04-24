class CreateQiitaAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :qiita_accounts do |t|
      t.string :url_name
      t.belongs_to :user, foreign_key: true

      t.timestamps
    end
  end
end
