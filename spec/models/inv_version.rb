class InvVersion < ActiveRecord::Base
  belongs_to :inv_object, inverse_of: :inv_versions
  has_many :inv_files, inverse_of: :inv_version
  has_many :inv_dublinkernels
end
