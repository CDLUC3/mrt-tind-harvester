class InvObject < ActiveRecord::Base
  belongs_to :inv_owner

  has_many :inv_collections_inv_objects
  has_many :inv_collections, through: :inv_collections_inv_objects

  has_many :inv_versions, inverse_of: :inv_object
  has_many :inv_files, through: :inv_versions

  has_many(:inv_localids, foreign_key: 'inv_object_ark', primary_key: 'ark')
end
