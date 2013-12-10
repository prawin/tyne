# Represents an user
class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable
         
  validates :name, :presence => true
  attr_accessible :name, :username, :uid, :email, :token, :gravatar_id, :notification_email, :password, :password_confirmation, :avatar
  attr_accessor :real_content_type

  has_many :organization_memberships
  has_many :organizations, :through => :organization_memberships
  has_many :projects
  has_many :team_members
  has_many :teams, :through => :team_members
  has_many :owned_projects, :through => :teams, :class_name => "Project", :source => :project, :conditions => { :teams => { :admin_privileges => true } }
  has_many :accessible_projects, :through => :teams, :class_name => "Project", :source => :project
  has_many :dashboards
  has_many :issues, :through => :projects
  has_many :reported_issues, :class_name => "Issue", :foreign_key => :reported_by_id
  has_attached_file :avatar, :styles => {:medium => "122x122", :thumb => "50x"},
                    :path => ":rails_root/public/system/:class/:attachment/:id/:style/:basename.:extension",
                    :url => "/system/:class/:attachment/:id/:style/:basename.:extension",
                    :default_url => "/assets/:attachment/:style/missing.jpg"

  after_initialize :set_defaults

  validates_attachment_size :avatar, :less_than => 5.megabytes, :message => "must be less than 5 Mb"
  validates_attachment_content_type :avatar, :content_type => ['image/jpeg', 'image/png', 'image/gif', 'image/pjpeg', 'image/x-png'], :message => "^Only jpg, png, jpeg files are allowed"
  validate :real_content_type_valid
  
  def real_content_type_valid
    if self.avatar_updated_at_changed? and (self.real_content_type =~ /^image.*/).nil?
      errors.add(:base, "Only jpg, png, jpeg files are allowed")
    end
  end

  before_post_process :image?

  def image?
    self.real_content_type =  `file --mime -b #{self.avatar.queued_for_write[:original].path}`
    self.real_content_type.sub! /\s*;.*$/, ''
    !(self.real_content_type =~ /^image.*/).nil?
  end


  # Returns a Github API wrapper.
  #
  # @return Octokit::Client
  def github_client
    Octokit::Client.new(:login => username, :oauth_token => token)
  end

  # Returns the first dashboard in the list.
  # This method is supposed to return the dashboard that's marked as default in the nearer future.
  #
  # @return [Dashboard] default dashboard
  def default_dashboard
    dashboards.first
  end

  def set_defaults
    self.dashboards.build(:name => "Default")
  end
  private :set_defaults
end
