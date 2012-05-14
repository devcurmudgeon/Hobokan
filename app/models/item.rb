# encoding: utf-8

class Item < ActiveRecord::Base

  hobo_model # Don't put anything above this
  versioned

  fields do
    start_date         :date
    end_date           :date
    title              :string
    text               :markdown
    result             :markdown
    doable             :boolean
    position           :integer
    timestamps
  end

  set_search_columns :title, :text, :result

  # validates_date :start_date, :on_or_after => Date.today
  # validates_date :end_date, :on_or_after => Date.today

  has_many :item_assignments, :dependent => :destroy
  has_many :project_members, :through => :item_assignments, :accessible => true
  has_many :comments

  belongs_to :user, :class_name => "User", :creator => true
  belongs_to :lane
  belongs_to :project
  belongs_to :milestone

  # acts_as_list :scope => :lane
  set_default_order "position DESC"

  lifecycle do
    state :normal, :default => true
    state :created
    state :urgent
    state :archived

    transition :archive, { :normal => :archived }, :available_to => "User"
    transition :archive, { :created => :archived }, :available_to => "User"
    transition :restore, { :archived => :normal }, :available_to => "User"
  end

  scope :active, :conditions => "state != 'archived'"
  scope :todo, :joins => "INNER JOIN lanes ON items.lane_id = lanes.id", :conditions => "lanes.todo = 't' "
  scope :done, :joins => "INNER JOIN lanes ON items.lane_id = lanes.id", :conditions => "lanes.todo != 't' "

  before_create :set_lane, :enqueue_item, :set_updated_by
  before_save :set_updated_by

  def set_updated_by
    if project.nil?
      members = lane.project.project_members
    else
      members = project.project_members
    end
    member = members.find(:first, :conditions => "user_id = #{User.current.id}")
    self.updated_by = (member ? member : User.current)
  end

  def set_lane
    if self.lane == nil
      self.lane = project.lanes.visible[0]
    end
  end

  def enqueue_item
    self.position = lane.items.count + 1
  end

  def versions
    v = Version.arel_table
    return Version.where(:versioned_id => id).where(v[:modifications].matches("%lane_id%")).order("created_at DESC").limit(50)
  end

  # --- Permissions --- #

  def create_permitted?
    project_id.nil? || ProjectMember.memberships.include?(project_id)
    true
   end

  def update_permitted?
    ProjectMember.memberships.include?(project_id)
  end

  def destroy_permitted?
    ProjectMember.memberships.include?(project_id)
  end

  def view_permitted?(field)
    project_id.nil? || ProjectMember.view_memberships.include?(project_id) || project.public_viewable
  end

end
