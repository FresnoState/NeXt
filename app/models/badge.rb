class Badge < ActiveRecord::Base

  acts_as_paranoid

  belongs_to :badge_category

  has_many :user_badges, dependent: :destroy
  has_many :users, through: :user_badges

  has_many :badge_roles, dependent: :destroy
  has_many :users, through: :badge_roles, source: :user

  has_many :badge_groups, dependent: :destroy
  has_many :groups, through: :badge_groups, source: :group

  mount_uploader :image, BadgeUploader

  def badge_editor_ids
    badge_roles.where(editor: true).map(&:user_id)
  end

  def badge_giver_ids
    badge_roles.where(giver: true).map(&:user_id)
  end

  def badge_editor_ids= user_ids
    badge_roles.where(owner: false, editor: true).destroy_all

    user_ids.reject(&:blank?).each do |user_id|
      user = User.find user_id
      next if user.nil?

      existing_role = badge_roles.find_by_user_id user.id
      if existing_role.nil?
        badge_roles << BadgeRole.new(user: user, editor: true)
      else
        existing_role.editor = true
        existing_role.save
      end
    end
  end

  def badge_giver_ids= user_ids
    badge_roles.where(owner: false, giver: true).destroy_all

    user_ids.reject(&:blank?).each do |user_id|
      user = User.find user_id
      next if user.nil?

      existing_role = badge_roles.find_by_user_id user.id
      if existing_role.nil?
        badge_roles << BadgeRole.new(user: user, giver: true)
      else
        existing_role.giver = true
        existing_role.save
      end
    end
  end

  def self.is_creatable_by? user
    if user.nil?
      return false
    else
      return user.super_admin
    end
  end

  def is_owned_by? user
    if user.nil?
      return false
    elsif user.super_admin
      return true
    else
      return BadgeRole.where(user_id: user.id, owner: true).count > 0
    end
  end

  def is_editable_by? user
    if user.nil?
      return false
    elsif is_owned_by? user
      return true
    else
      return BadgeRole.where(user_id: user.id, editor: true).count > 0
    end
  end

  def is_givable_by? user
    if user.nil?
      return false
    elsif is_editable_by? user
      return true
    else
      return BadgeRole.where(user_id: user.id, giver: true).count > 0
    end
  end

  def is_givable_to? user
    if user.nil?
      return false
    elsif user.badges.include? self
      return false
    else
      return true
    end
  end

end
