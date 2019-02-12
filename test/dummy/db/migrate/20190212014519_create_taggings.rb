class CreateTaggings < ActiveRecord::Migration[5.2]
  def change
    create_table :taggings do |t|
      t.belongs_to :taggable, polymorphic: true
      t.belongs_to :tag
      t.timestamps
    end
  end
end
